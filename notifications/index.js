/**
 * Firebase Scheduled Function to send daily attendance reminder to parents
 */

const { setGlobalOptions } = require("firebase-functions/v2");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore"); // ✅ إضافة استيراد مراقب المستندات
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

// الدالة الأولى (التنبيه اليومي المجدول)
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

// ✅ الدالة الثانية (التتبع والإشعارات المباشرة)
exports.sendLiveNotification = onDocumentCreated("LiveNotifications/{docId}", async (event) => {
    const data = event.data.data();
    if (!data) return;

    const { type, targetPhone, busId, title, body } = data;
    let tokens = [];

    try {
        if (type === "individual" && targetPhone) {
            // جلب توكن ولي أمر محدد (تنبيه اقتراب الحافلة)
            const userDoc = await admin.firestore().collection("users").doc(targetPhone).get();
            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
            }
        } 
        else if (type === "broadcast" && busId) {
            // جلب توكنات جميع أولياء أمور الطلاب في هذه الحافلة (تنبيه المدرسة)
            const studentsSnap = await admin.firestore().collection("Students").where("BusID", "==", busId).get();
            const parentPhones = new Set();
            
            studentsSnap.forEach(doc => {
                const phone = doc.data().parentPhone;
                if (phone) parentPhones.add(phone);
            });

            // جلب التوكنات لأولياء الأمور
            for (const phone of parentPhones) {
                const userDoc = await admin.firestore().collection("users").doc(phone).get();
                if (userDoc.exists && userDoc.data().fcmToken) {
                    tokens.push(userDoc.data().fcmToken);
                }
            }
        }

        if (tokens.length === 0) {
            console.log("No tokens found for this notification.");
            return;
        }

        const message = {
            notification: { title, body },
            data: { screen: "manage_child" }, // تحويل الوالد إلى شاشة تتبع الابن عند النقر
            tokens: tokens,
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Live Notification Sent: ${response.successCount} success, ${response.failureCount} failed.`);

        // تنظيف قاعدة البيانات بحذف المستند بعد الإرسال بنجاح
        await event.data.ref.delete();

    } catch (error) {
        console.error("Error sending live notification:", error);
    }
});