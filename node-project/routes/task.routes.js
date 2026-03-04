const express = require('express');
const router = express.Router();
const taskController = require('../controllers/task.controller');
const reminderController = require('../controllers/reminder.controller');
const authMiddleware = require('../middleware/auth.middleware');
 
router.use(authMiddleware);
 
router.get('/', taskController.getAllTasks);
router.post('/create', taskController.createTask);
router.put('/:id', taskController.updateTask);
router.delete('/:id', taskController.deleteTask);
router.delete('/delete', taskController.deleteTask);
router.get("/home", taskController.getTasksForHome);
router.get("/home/summary", taskController.getHomeSummary);
 
// Reminder endpoints (nested under tasks)
router.get('/:taskId/reminder', reminderController.getReminder);
router.post('/:taskId/reminder', reminderController.createReminder);
router.put('/:taskId/reminder', reminderController.updateReminder);
router.delete('/:taskId/reminder', reminderController.deleteReminder);
 
module.exports = router;
 