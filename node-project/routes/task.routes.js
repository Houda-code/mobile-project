const express = require('express');
const router = express.Router();
const taskController = require('../controllers/task.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.use(authMiddleware);

router.get('/', taskController.getAllTasks);
router.post('/create', taskController.createTask);
router.put('/:id', taskController.updateTask);
router.delete('/:id', taskController.deleteTask);
router.delete('/delete', taskController.deleteTask);
router.get("/home", taskController.getTasksForHome);

module.exports = router;
