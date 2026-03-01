const express = require('express');
const router = express.Router();
const professorController = require('../controllers/professor.controller');
const authMiddleware = require('../middleware/auth.middleware');
const requireRole = require('../middleware/require_role.middleware');

router.use(authMiddleware);
router.use(requireRole('PROFESSOR'));

router.get('/dashboard', professorController.getDashboard);
router.get('/students/:id/tasks', professorController.getStudentTasks);
router.get('/students/:id/summary', professorController.getStudentSummary);
router.post('/students/:id/tasks', professorController.createTaskForStudent);
router.post('/classes/:className/tasks', professorController.createTaskForClass);

module.exports = router;
