import {onCall, HttpsError} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2/options";
import * as admin from "firebase-admin";
import {GoogleGenerativeAI} from "@google/generative-ai";

// Initialize Firebase Admin
admin.initializeApp();

// Global options for cost control
setGlobalOptions({maxInstances: 10});

// Scene configurations for AI generation
// Prompts designed for realistic, phone-shot style photos
// Common negative prompt to avoid AI-looking results
const NEGATIVE_PROMPT =
  "Always show the person's full face clearly visible, not cropped. " +
  "Avoid: cropped face, cut off head, artificial look, obvious photoshop, " +
  "CGI appearance, mismatched lighting, distorted face, warped features, " +
  "unnatural skin smoothing, plastic skin, oversaturated colors, " +
  "studio backdrop, stiff pose, watermarks, text overlays.";

const SCENES = [
  {
    id: "beach",
    label: "Beach",
    prompt:
      "Place this exact person naturally into a tropical beach scene. " +
      "Shot on iPhone, candid vacation photo style. " +
      "Golden hour soft lighting, person appears relaxed and natural. " +
      "Background: turquoise water, soft sand, palm trees slightly blurred. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Natural smartphone photo quality - not overly sharp or processed. " +
      "The person should look like they belong in this scene. " +
      NEGATIVE_PROMPT,
  },
  {
    id: "city",
    label: "City",
    prompt:
      "Place this exact person naturally into an urban city street scene. " +
      "Shot on iPhone, casual street photography style. " +
      "Evening blue hour with warm street lights and shop signs. " +
      "Background: busy city street, blurred lights, urban architecture. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Natural depth of field as if shot on phone portrait mode. " +
      "Candid moment - person looks natural, not posing for camera. " +
      NEGATIVE_PROMPT,
  },
  {
    id: "mountain",
    label: "Mountain",
    prompt:
      "Place this exact person naturally into a mountain hiking scene. " +
      "Shot on iPhone, adventure travel photo style. " +
      "Bright daylight with natural sun, scenic mountain vista behind. " +
      "Background: mountain peaks, hiking trail, nature landscape. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Natural outdoor lighting with soft shadows. " +
      "Authentic travel moment - person enjoying the view naturally. " +
      NEGATIVE_PROMPT,
  },
  {
    id: "cafe",
    label: "Cafe",
    prompt:
      "Place this exact person naturally into a cozy cafe setting. " +
      "Shot on iPhone, lifestyle photography style. " +
      "Soft indoor lighting, warm ambient tones from cafe lights. " +
      "Background: coffee shop interior, latte on table, soft blur. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Intimate casual moment - person relaxed, natural expression. " +
      "Window light creating soft, flattering illumination. " +
      NEGATIVE_PROMPT,
  },
  {
    id: "forest",
    label: "Forest",
    prompt:
      "Place this exact person naturally into a lush forest scene. " +
      "Shot on iPhone, nature photography style. " +
      "Dappled sunlight filtering through trees, green tones. " +
      "Background: tall trees, ferns, natural forest path. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Peaceful nature moment - person at ease in natural surroundings. " +
      "Soft natural lighting with gentle shadows from foliage. " +
      NEGATIVE_PROMPT,
  },
  {
    id: "sunset",
    label: "Sunset",
    prompt:
      "Place this exact person naturally into a beautiful sunset scene. " +
      "Shot on iPhone, golden hour photography style. " +
      "Warm orange and pink sunset light illuminating the person. " +
      "Background: dramatic sky with clouds, horizon line, silhouettes. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Warm glow on skin, subtle natural lens flare okay. " +
      "Dreamy atmosphere but still realistic photo quality. " +
      NEGATIVE_PROMPT,
  },
  {
    id: "snow",
    label: "Snow",
    prompt:
      "Place this exact person naturally into a winter snow scene. " +
      "Shot on iPhone, winter travel photo style. " +
      "Bright overcast lighting, soft and even illumination. " +
      "Background: snow-covered landscape, pine trees, winter atmosphere. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Cold weather vibe - rosy cheeks natural. " +
      "Clean white snow, cozy winter moment captured candidly. " +
      NEGATIVE_PROMPT,
  },
  {
    id: "garden",
    label: "Garden",
    prompt:
      "Place this exact person naturally into a blooming garden scene. " +
      "Shot on iPhone, spring lifestyle photography style. " +
      "Soft diffused daylight, fresh and bright atmosphere. " +
      "Background: colorful flowers, green plants, garden path or bench. " +
      "Keep exact face features, skin tone, hair, and clothing unchanged. " +
      "Peaceful garden moment - person enjoying nature, relaxed pose. " +
      "Natural colors, authentic outdoor photo feel. " +
      NEGATIVE_PROMPT,
  },
];

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
    const {imageUrl, imagePath, sceneIds} = request.data as GenerateRequest;

    if (!imageUrl || !imagePath || !sceneIds || sceneIds.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "imageUrl, imagePath, and sceneIds are required"
      );
    }

    // 2b. Validate all scenes exist
    const selectedScenes = sceneIds
      .map((id) => SCENES.find((s) => s.id === id))
      .filter((s): s is (typeof SCENES)[number] => s !== undefined);

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

      // Generate all selected scenes
      for (const scene of selectedScenes) {
        try {
          console.log(`Generating ${scene.id} scene...`);

          const result = await model.generateContent([
            {
              inlineData: {
                mimeType: mimeType,
                data: base64Image,
              },
            },
            scene.prompt,
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
