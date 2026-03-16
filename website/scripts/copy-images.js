const fs = require('fs');
const path = require('path');

const mapping = {
  '104f3b21-10d9-48aa-b686-9a64b45a9fc0.jpg': 'app-insights.jpg',
  '56dc23fe-8e7c-45c7-9032-84ff4e9cd534.jpg': 'app-nutrition.jpg',
  '2dbe3ad0-5cea-4f8c-ba47-668bd62ec83c.jpg': 'app-recipes.jpg',
  '18cce20d-38cb-4349-b925-590e8d69af16.jpg': 'app-dashboard.jpg',
  '67b5c928-510b-4bb0-b0d1-e1488de50850.jpg': 'app-workout.jpg',
  'fd634502-238c-4142-8647-eda5734c24da.jpg': 'app-mood.jpg',
};

const assetsDir = path.join(__dirname, '..', 'assets');
const publicDir = path.join(__dirname, '..', 'public');

console.log('Assets dir:', assetsDir);
console.log('Public dir:', publicDir);
console.log('Assets exists:', fs.existsSync(assetsDir));
console.log('Public exists:', fs.existsSync(publicDir));

let copied = 0;
let notFound = 0;

Object.entries(mapping).forEach(([source, dest]) => {
  const sourcePath = path.join(assetsDir, source);
  const destPath = path.join(publicDir, dest);
  
  console.log(`Checking: ${sourcePath}`);
  console.log(`Exists: ${fs.existsSync(sourcePath)}`);
  
  if (fs.existsSync(sourcePath)) {
    try {
      fs.copyFileSync(sourcePath, destPath);
      console.log(`✓ Copied: ${source} -> ${dest}`);
      copied++;
    } catch (error) {
      console.error(`✗ Error copying ${source}:`, error.message);
    }
  } else {
    console.error(`✗ Not found: ${source}`);
    notFound++;
  }
});

console.log(`\nDone! Copied: ${copied}, Not found: ${notFound}`);

