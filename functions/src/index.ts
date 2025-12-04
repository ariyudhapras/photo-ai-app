import {onCall, HttpsError} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2/options";
import * as admin from "firebase-admin";
import {GoogleGenerativeAI} from "@google/generative-ai";

// Initialize Firebase Admin
admin.initializeApp();

// Global options for cost control
setGlobalOptions({maxInstances: 10});

// Scene descriptions for dynamic prompt building
const SCENE_DESCRIPTIONS: Record<
  string,
  { label: string; description: string }
> = {
  beach: {
    label: "Beach",
    description:
      "a tropical beach with turquoise water, soft sand, " +
      "and palm trees in the background during golden hour",
  },
  city: {
    label: "City",
    description:
      "an urban city street at blue hour with warm street lights, " +
      "shop signs, and blurred urban architecture in the background",
  },
  mountain: {
    label: "Mountain",
    description:
      "a scenic mountain hiking trail with mountain peaks " +
      "and natural landscape visible in bright daylight",
  },
  cafe: {
    label: "Cafe",
    description:
      "a cozy cafe interior with soft window light, " +
      "warm ambient tones, and a coffee on the table",
  },
  forest: {
    label: "Forest",
    description:
      "a lush green forest with tall trees, ferns, " +
      "and dappled sunlight filtering through the foliage",
  },
  sunset: {
    label: "Sunset",
    description:
      "a scenic location during sunset with warm orange and pink sky, " +
      "dramatic clouds, and golden hour lighting",
  },
  snow: {
    label: "Snow",
    description:
      "a winter snow-covered landscape with pine trees " +
      "and soft overcast lighting",
  },
  garden: {
    label: "Garden",
    description:
      "a blooming garden with colorful flowers, green plants, " +
      "and soft diffused daylight",
  },
};

/**
 * Builds a realistic photo generation prompt for any scene.
 * Uses a universal template with dynamic scene description injection.
 * @param {string} sceneDescription - The scene description to inject.
 * @return {string} The complete prompt for image generation.
 */
function buildRealisticPrompt(sceneDescription: string): string {
  return (
    "Generate a realistic photograph featuring the same person from the " +
    "provided portrait. Keep the face and skin tone consistent with the " +
    "original image. The output must look like a natural phone-shot " +
    "photo.\n\n" +
    "Blend the person seamlessly into the new scene with correct " +
    "lighting, shadows, and perspective. Avoid AI-looking edges, halos, " +
    "or cutout artifacts. Preserve clothing and body orientation unless " +
    "the scene requires minor adjustments.\n\n" +
    `Scene: ${sceneDescription}\n\n` +
    "Constraints:\n" +
    "- No stylized or artistic effects\n" +
    "- No filters, HDR, surreal colors, or painterly textures\n" +
    "- No cartoon-like rendering\n" +
    "- Maintain realistic depth of field and mobile-camera optics\n" +
    "- Output in standard photo aspect ratio\n" +
    "- Always show the person's full face clearly visible, not cropped"
  );
}

interface GenerateRequest {
  imageUrl: string;
  imagePath: string;
  sceneIds: string[];
}

interface GeneratedImage {
  path: string;
  scene: string;
}

/**
 * Cloud Function to generate AI scenes from an uploaded image.
 * Uses Google Gemini API for image generation.
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
    const {imageUrl, imagePath, sceneIds} = request.data as GenerateRequest;

    if (!imageUrl || !imagePath || !sceneIds || sceneIds.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "imageUrl, imagePath, and sceneIds are required"
      );
    }

    // 2b. Validate all scenes exist
    const selectedScenes = sceneIds
      .map((id) => {
        const scene = SCENE_DESCRIPTIONS[id];
        return scene ? {id, ...scene} : undefined;
      })
      .filter(
        (s): s is { id: string; label: string; description: string } =>
          s !== undefined
      );

    if (selectedScenes.length === 0) {
      throw new HttpsError("invalid-argument", "No valid scenes selected");
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

      const validTypes = ["image/jpeg", "image/jpg", "image/png"];
      if (!validTypes.includes(baseContentType)) {
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

      // Use Gemini 2.5 Flash Image for better quality generation
      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash-image",
        generationConfig: {
          responseModalities: ["TEXT", "IMAGE"],
        } as never,
      });

      // Generate all selected scenes
      for (const scene of selectedScenes) {
        try {
          console.log(`Generating ${scene.id} scene...`);

          // Build the realistic prompt with the scene description
          const prompt = buildRealisticPrompt(scene.description);
          console.log(`Using prompt for ${scene.id}`);

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

                const genPath = `users/${uid}/generated/${generationId}`;
                const storagePath = `${genPath}/${scene.id}.png`;
                const file = bucket.file(storagePath);

                const imageData = Buffer.from(inlineData.data, "base64");
                await file.save(imageData, {
                  metadata: {
                    contentType: inlineData.mimeType || "image/png",
                  },
                });

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
