/**
 * Firebase Scheduled Function to send daily attendance reminder to parents
 */

const { setGlobalOptions } = require("firebase-functions/v2");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

exports.sendAttendanceReminder = onSchedule(
    {
        schedule: "0 19 * * *", // كل يوم الساعة 7 مساء
        timeZone: "Asia/Riyadh",
    },
    async () => {
        try {
            const snapshot = await admin
                .firestore()
                .collection("users")
                .where("role", "==", "parent")
                .get();

            const tokens = [];

            snapshot.forEach((doc) => {
                const data = doc.data();
                const token = data.fcmToken;

                if (token && typeof token === "string" && token.trim() !== "") {
                    tokens.push(token);
                }
            });

            if (tokens.length === 0) {
                console.log("No parent tokens found.");
                return;
            }

            // تقسيم التوكنات لأن FCM يسمح بحد أقصى 500 في الطلب الواحد
            const chunks = [];
            for (let i = 0; i < tokens.length; i += 500) {
                chunks.push(tokens.slice(i, i + 500));
            }

            for (const chunk of chunks) {
                const message = {
                    notification: {
                        title: "تأكيد حضور الطالب",
                        body: "يرجى تأكيد حضور ابنك للباص ليوم الغد قبل الساعة 5 صباحًا",
                    },
                    data: {
                        screen: "parent_home",
                        type: "attendance_reminder",
                    },
                    tokens: chunk,
                };

                const response = await admin.messaging().sendEachForMulticast(message);

                console.log(
                    `Sent: ${response.successCount}, Failed: ${response.failureCount}`
                );
            }
        } catch (error) {
            console.error("Error sending notifications:", error);
        }
    }
);