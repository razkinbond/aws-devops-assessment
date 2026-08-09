const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>AWS Assessment App</title>
        <style>
          body { font-family: sans-serif; text-align: center; margin-top: 100px; background: #f9f9f9; }
          .card { background: white; padding: 40px; border-radius: 8px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
          h1 { color: #232f3e; }
          p { color: #555; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>🚀 AWS DevOps Assessment</h1>
          <p>Frontend deployed on AWS ECS Fargate via GitHub Actions CI/CD</p>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Frontend running on port ${PORT}`);
});