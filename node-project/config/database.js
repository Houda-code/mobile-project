// const { Sequelize } = require('sequelize');

// const databaseName = 'task_app';
// const dbUser = 'root';
// const dbPassword = 'azerty1234*'; // ou ton mot de passe
// const dbHost = 'localhost';

// // 1️⃣ Connexion temporaire pour créer la DB
// const sequelizeTemp = new Sequelize('', dbUser, dbPassword, {
//   host: dbHost,
//   dialect: 'mysql',
//   logging: console.log,
// });

// const connectAndCreateDB = async () => {
//   try {
//     await sequelizeTemp.authenticate();
//     console.log('Connection to MySQL server successful');

//     // Créer la DB si elle n'existe pas
//     await sequelizeTemp.query(`CREATE DATABASE IF NOT EXISTS \`${databaseName}\`;`);
//     console.log(`Database "${databaseName}" is ready`);

//     // 2️⃣ Créer une nouvelle instance Sequelize qui utilise la DB
//     const sequelize = new Sequelize(databaseName, dbUser, dbPassword, {
//       host: dbHost,
//       dialect: 'mysql',
//       logging: console.log,
//     });

//     await sequelize.authenticate();
//     console.log('Connected to database task_app');

//     return sequelize;
//   } catch (error) {
//     console.error('Unable to connect to MySQL:', error);
//     process.exit(1);
//   }
// };

// module.exports = { connectAndCreateDB };
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('task_app', 'root', 'azerty1234*', {
  host: 'localhost',
  dialect: 'mysql',
  logging: console.log,
});

module.exports = sequelize;
