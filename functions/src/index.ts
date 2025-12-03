import {onCall, HttpsError} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2/options";
import * as admin from "firebase-admin";
import {GoogleGenerativeAI} from "@google/generative-ai";

// Initialize Firebase Admin
admin.initializeApp();

// Global options for cost control
setGlobalOptions({maxInstances: 10});

// Scene configurations for AI generation
// Prompts designed for natural, candid Instagram-style photos
const SCENES = [
  {
    id: "beach",
    label: "Beach",
    prompt:
      "relaxing at a beautiful tropical beach during golden hour, " +
      "soft natural sunlight, turquoise water in background, " +
      "casual vacation vibe, candid moment",
  },
  {
    id: "city",
    label: "City",
    prompt:
      "exploring a vibrant city street at dusk, " +
      "warm street lights and neon signs in background, " +
      "urban lifestyle aesthetic, natural street photography style",
  },
  {
    id: "mountain",
    label: "Mountain",
    prompt:
      "hiking adventure with stunning mountain vista behind, " +
      "crisp morning light, nature exploration mood, " +
      "authentic outdoor travel moment",
  },
  {
    id: "cafe",
    label: "Cafe",
    prompt:
      "enjoying coffee at a charming European sidewalk cafe, " +
      "soft afternoon light, cozy atmosphere with string lights, " +
      "relaxed lifestyle moment",
  },
];

interface GenerateRequest {
  imageUrl: string;
  imagePath: string;
}

interface GeneratedImage {
  path: string;
  scene: string;
}

/**
 * Cloud Function to generate AI scenes from an uploaded image.
 * Uses Google Gemini API with Imagen 3 for image generation.
 */
export const generateAIScenes = onCall(
  {
    timeoutSeconds: 540,
    memory: "2GiB",
    secrets: ["GEMINI_API_KEY"],
  },
  async (request) => {
    // 1. Validate authentication
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Must be authenticated to use this function"
      );
    }

    // 2. Validate request data
    const {imageUrl, imagePath} = request.data as GenerateRequest;

    if (!imageUrl || !imagePath) {
      throw new HttpsError(
        "invalid-argument",
        "imageUrl and imagePath are required"
      );
    }

    // 3. Validate image path ownership
    if (!imagePath.startsWith(`users/${uid}/`)) {
      throw new HttpsError(
        "permission-denied",
        "You can only process your own images"
      );
    }

    // 4. Initialize Gemini API
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error("GEMINI_API_KEY not configured");
      throw new HttpsError("internal", "AI service not configured");
    }

    const genAI = new GoogleGenerativeAI(apiKey);

    try {
      // 5. Fetch the original image
      const imageResponse = await fetch(imageUrl);
      if (!imageResponse.ok) {
        throw new HttpsError("not-found", "Could not fetch the original image");
      }

      // 5a. Validate MIME type (must be JPEG or PNG)
      const rawContentType = imageResponse.headers.get("content-type") ?? "";
      // Extract base MIME type (remove charset and other parameters)
      const baseContentType = rawContentType.split(";")[0].trim().toLowerCase();

      if (!["image/jpeg", "image/jpg", "image/png"].includes(baseContentType)) {
        throw new HttpsError(
          "invalid-argument",
          "Uploaded file must be a JPEG or PNG image."
        );
      }

      const imageBuffer = await imageResponse.arrayBuffer();
      const base64Image = Buffer.from(imageBuffer).toString("base64");

      // Normalize MIME type for Gemini (convert jpg to jpeg)
      const mimeType =
        baseContentType === "image/jpg" ? "image/jpeg" : baseContentType;
      console.log(`Image MIME type: ${mimeType}`);

      // 6. Generate scenes using Gemini with image output
      const generationId = `gen_${Date.now()}_${Math.random()
        .toString(36)
        .substring(7)}`;
      const generatedImages: GeneratedImage[] = [];
      const bucket = admin.storage().bucket();

      // Use Gemini 2.0 Flash with image generation capability
      const model = genAI.getGenerativeModel({
        model: "gemini-2.0-flash-exp-image-generation",
        generationConfig: {
          responseModalities: ["TEXT", "IMAGE"],
        } as never,
      });

      for (const scene of SCENES) {
        try {
          console.log(`Generating ${scene.id} scene...`);

          const prompt =
            "Create a natural, candid photo of this person " +
            `${scene.prompt}. ` +
            "Keep the person's face, features, and outfit exactly the same. " +
            "Make it look like a real photo taken by a friend, " +
            "not a studio shot. Natural lighting, relaxed pose. " +
            "High quality, Instagram-ready.";

          const result = await model.generateContent([
            {
              inlineData: {
                mimeType: mimeType,
                data: base64Image,
              },
            },
            prompt,
          ]);

          const response = result.response;
          const parts = response.candidates?.[0]?.content?.parts;

          console.log(`${scene.id} response parts:`, parts?.length || 0);

          // Check if we got an image back
          if (parts) {
            for (const part of parts) {
              // Check for inline image data
              const inlineData = (
                part as {
                  inlineData?: {
                    mimeType?: string;
                    data?: string;
                  };
                }
              ).inlineData;

              if (inlineData?.data) {
                console.log(`Found image for ${scene.id}`);

                // Upload generated image to Storage (protected by rules)
                const genPath = `users/${uid}/generated/${generationId}`;
                const storagePath = `${genPath}/${scene.id}.png`;
                const file = bucket.file(storagePath);

                const imageData = Buffer.from(inlineData.data, "base64");
                await file.save(imageData, {
                  metadata: {
                    contentType: inlineData.mimeType || "image/png",
                  },
                });

                // Return storage path (client will get download URL via SDK)
                generatedImages.push({
                  path: storagePath,
                  scene: scene.id,
                });

                console.log(`Uploaded ${scene.id} to ${storagePath}`);
                break;
              }
            }
          }
        } catch (sceneError) {
          console.error(`Error generating ${scene.id}:`, sceneError);
          // Continue with other scenes even if one fails
        }
      }

      // 7. Check if we generated any images
      if (generatedImages.length === 0) {
        throw new HttpsError(
          "internal",
          "Failed to generate images. The AI model may be unavailable."
        );
      }

      // 8. Save generation record to Firestore
      await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .collection("generations")
        .doc(generationId)
        .set({
          id: generationId,
          originalImageUrl: imageUrl,
          generatedImages: generatedImages,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(
        `Generation ${generationId} completed with ` +
          `${generatedImages.length} images`
      );

      // 9. Return success response with storage paths
      return {
        success: true,
        generationId: generationId,
        images: generatedImages,
      };
    } catch (error) {
      console.error("Generation error:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Failed to generate images. Please try again."
      );
    }
  }
);
