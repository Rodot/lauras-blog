#!/usr/bin/env node
import { readdir, readFile } from "fs/promises";
import { join, relative } from "path";

// Supported image extensions
const IMAGE_EXTENSIONS = [".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"];

/**
 * Recursively find all files in a directory matching the given extensions
 */
async function findFiles(dir: string, extensions: string[]): Promise<string[]> {
  const files: string[] = [];
  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await findFiles(fullPath, extensions)));
    } else if (entry.isFile()) {
      const ext = entry.name
        .substring(entry.name.lastIndexOf("."))
        .toLowerCase();
      if (extensions.includes(ext)) {
        files.push(fullPath);
      }
    }
  }

  return files;
}

/**
 * Extract all image references from markdown content
 */
function extractImageReferences(content: string): string[] {
  const matches: string[] = [];

  // Match markdown image syntax: ![...](@/assets/content/...)
  const markdownRegex = /!\[.*?\]\((@\/assets\/content\/[^)]+)\)/g;
  let match;
  while ((match = markdownRegex.exec(content)) !== null) {
    matches.push(match[1]);
  }

  // Match YAML frontmatter image fields: image: "@/assets/content/..."
  const yamlRegex = /["'](@\/assets\/content\/[^"']+)["']/g;
  while ((match = yamlRegex.exec(content)) !== null) {
    matches.push(match[1]);
  }

  return matches;
}

/**
 * Convert @/assets/content/... path to actual file path
 */
function resolveAssetPath(assetPath: string): string {
  // Remove @/ prefix and return the rest (without leading ./)
  return assetPath.replace(/^@\//, "src/");
}

async function main() {
  console.log("🔍 Checking for unused images in ./src/assets/content/...\n");

  // Find all image files
  const imageFiles = await findFiles("./src/assets/content", IMAGE_EXTENSIONS);
  console.log(`Found ${imageFiles.length} image files`);

  // Find all markdown files
  const mdFiles = await findFiles("./src/content", [".md"]);
  console.log(`Found ${mdFiles.length} markdown files\n`);

  // Extract all image references from markdown files
  const referencedPaths = new Set<string>();

  for (const mdFile of mdFiles) {
    const content = await readFile(mdFile, "utf-8");
    const references = extractImageReferences(content);

    for (const ref of references) {
      const resolvedPath = resolveAssetPath(ref);
      referencedPaths.add(resolvedPath);
    }
  }

  console.log(`Found ${referencedPaths.size} unique image references\n`);

  // Find unused images
  const unusedImages: string[] = [];

  for (const imageFile of imageFiles) {
    if (!referencedPaths.has(imageFile)) {
      unusedImages.push(imageFile);
    }
  }

  // Report results
  if (unusedImages.length > 0) {
    console.error(`❌ Found ${unusedImages.length} unused image(s):\n`);
    for (const img of unusedImages.sort()) {
      console.error(`  - ${relative(".", img)}`);
    }
    console.error(
      "\nPlease remove unused images or add them to markdown files.\n",
    );
    process.exit(1);
  } else {
    console.log("✅ All images are being used!\n");
    process.exit(0);
  }
}

main().catch((error) => {
  console.error("Error checking images:", error);
  process.exit(1);
});
