const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Deletar usuário
exports.deleteUser = functions.https.onCall(async (data, context) => {
  const uid = data.uid;

  // Aqui você pode proteger com lógica adicional (verificar se o context.auth.uid é admin)

  try {
    await admin.auth().deleteUser(uid);
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Atualizar email
exports.updateUserEmail = functions.https.onCall(async (data, context) => {
  const uid = data.uid;
  const newEmail = data.newEmail;

  try {
    await admin.auth().updateUser(uid, {
      email: newEmail,
    });
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
