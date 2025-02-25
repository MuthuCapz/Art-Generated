const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

exports.checkInactiveUsers = onSchedule("every 1 minutes", async () => {
  const db = admin.firestore();
  const usersRef = db.collection("artgen_users");
  const now = new Date();
  const oneMinuteAgo = new Date(now);

  // Subtract 1 minute from current time
  oneMinuteAgo.setMinutes(now.getMinutes() - 1);

  try {
    const snapshot = await usersRef
        .where("updateDateTime", "<=", oneMinuteAgo.toISOString())
        .get();

    if (!snapshot.empty) {
      const batch = db.batch();

      snapshot.forEach((doc) => {
        batch.update(doc.ref, {status: "inactive"});
      });

      await batch.commit();
      console.log("Updated inactive users.");
    } else {
      console.log("No inactive users found.");
    }
  } catch (error) {
    console.error("Error updating inactive users:", error);
  }
});
