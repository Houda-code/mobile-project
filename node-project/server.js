require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');

const { sequelize, User, Task, Reminder } = require('./models'); // <- tout est là
const authRoutes = require('./routes/auth.routes');
const taskRoutes = require('./routes/task.routes');

const app = express();
app.use(bodyParser.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);

// Test route
app.get('/', (req, res) => {
  res.send('API is running');
});

// Sync DB and start server
sequelize.sync({ alter: true }) // alter: true met à jour la table si besoin
  .then(() => {
    console.log('Database synced');
    app.listen(3000, () => {
      console.log('Server running on port 3000');
    });
  })
  .catch(err => {
    console.error('Unable to sync database:', err);
  });
