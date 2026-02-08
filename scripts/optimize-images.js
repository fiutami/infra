#!/usr/bin/env node
/**
 * Image Optimization Script for Fiutami
 * Converts PNG/JPG images to WebP and AVIF formats
 * Creates responsive versions for different screen sizes
 *
 * Usage: node scripts/optimize-images.js
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const IMAGES_DIR = path.join(__dirname, '../src/assets/images');

// Images to convert with their settings
const imagesToConvert = [
  {
    input: 'auth-bg.png',
    outputs: [
      { format: 'webp', quality: 80, suffix: '' },
      { format: 'avif', quality: 50, suffix: '' },
    ],
    // Responsive versions for different breakpoints
    responsive: [
      { width: 480, suffix: '-480w' },    // Mobile
      { width: 768, suffix: '-768w' },    // Tablet
      { width: 1280, suffix: '-1280w' },  // Desktop
      { width: 1920, suffix: '-1920w' },  // Full HD
    ]
  },
  {
    input: 'logo-fiutami.png',
    outputs: [
      { format: 'webp', quality: 90, suffix: '' },
      { format: 'avif', quality: 60, suffix: '' },
    ]
  },
  {
    input: 'mascot-icon.png',
    outputs: [
      { format: 'webp', quality: 85, suffix: '' },
      { format: 'avif', quality: 55, suffix: '' },
    ]
  }
];

async function convertImage(inputPath, outputPath, format, quality, width = null) {
  let image = sharp(inputPath);

  // Resize if width specified
  if (width) {
    image = image.resize(width, null, { withoutEnlargement: true });
  }

  if (format === 'webp') {
    await image.webp({ quality, effort: 6 }).toFile(outputPath);
  } else if (format === 'avif') {
    await image.avif({ quality, effort: 6 }).toFile(outputPath);
  }

  const outputStats = fs.statSync(outputPath);
  return outputStats.size;
}

async function main() {
  console.log('🖼️  Image Optimization for Fiutami\n');

  for (const config of imagesToConvert) {
    const inputPath = path.join(IMAGES_DIR, config.input);

    if (!fs.existsSync(inputPath)) {
      console.log(`⚠️  Skipping ${config.input} (not found)`);
      continue;
    }

    const inputStats = fs.statSync(inputPath);
    console.log(`📁 ${config.input} (${(inputStats.size / 1024).toFixed(1)} KB)`);

    // Standard format conversion (full size)
    for (const output of config.outputs) {
      const baseName = path.basename(config.input, path.extname(config.input));
      const outputName = `${baseName}${output.suffix}.${output.format}`;
      const outputPath = path.join(IMAGES_DIR, outputName);

      try {
        const size = await convertImage(inputPath, outputPath, output.format, output.quality);
        const savings = ((1 - size / inputStats.size) * 100).toFixed(1);
        console.log(`  ${outputName}: ${(size / 1024).toFixed(1)} KB (${savings}% smaller)`);
      } catch (err) {
        console.error(`  ❌ Error converting to ${output.format}: ${err.message}`);
      }
    }

    // Responsive versions (if configured)
    if (config.responsive) {
      console.log('  📐 Responsive versions:');
      for (const resp of config.responsive) {
        const baseName = path.basename(config.input, path.extname(config.input));

        // Create WebP and AVIF for each size
        for (const format of ['webp', 'avif']) {
          const quality = format === 'webp' ? 80 : 50;
          const outputName = `${baseName}${resp.suffix}.${format}`;
          const outputPath = path.join(IMAGES_DIR, outputName);

          try {
            const size = await convertImage(inputPath, outputPath, format, quality, resp.width);
            console.log(`    ${outputName}: ${(size / 1024).toFixed(1)} KB`);
          } catch (err) {
            console.error(`    ❌ Error: ${err.message}`);
          }
        }
      }
    }

    console.log('');
  }

  console.log('✅ Image optimization complete!\n');

  // Show summary
  console.log('📊 Summary:');
  const files = fs.readdirSync(IMAGES_DIR).filter(f => !f.endsWith('.md') && !f.endsWith('.svg'));
  let totalOriginal = 0;
  let totalOptimized = 0;

  for (const file of files) {
    const filePath = path.join(IMAGES_DIR, file);
    const stats = fs.statSync(filePath);
    const ext = path.extname(file).toLowerCase();

    if (ext === '.png' || ext === '.jpg' || ext === '.jpeg') {
      totalOriginal += stats.size;
    } else if (ext === '.webp' || ext === '.avif') {
      totalOptimized += stats.size;
    }

    console.log(`  ${file}: ${(stats.size / 1024).toFixed(1)} KB`);
  }

  if (totalOriginal > 0 && totalOptimized > 0) {
    console.log(`\n💾 Total original: ${(totalOriginal / 1024).toFixed(1)} KB`);
    console.log(`💾 Total optimized (all sizes): ${(totalOptimized / 1024).toFixed(1)} KB`);
  }
}

main().catch(console.error);
