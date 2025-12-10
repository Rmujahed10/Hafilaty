import 'package:flutter/material.dart';

class DriverRegistrationScreen extends StatelessWidget {
  const DriverRegistrationScreen({super.key});

  // ويدجيت مخصص لتمثيل حقل الإدخال مع التسمية (Label) في الأعلى
  Widget _buildLabeledTextField({
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. التسمية (الاسم الأول، رقم الهوية، إلخ)
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 6.0),
          child: Text(
            labelText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 2. حقل الإدخال نفسه
        TextFormField(
          obscureText: isPassword,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),

            // **الأيقونة في اليمين (prefixIcon في اتجاه RTL)**
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Icon(icon, color: Colors.grey.shade500),
            ),

            // تم حذف suffixIcon وأيقونة الدور منه
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Color(0xFF0D47A1),
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 15,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // تعيين الاتجاه لـ RTL (من اليمين لليسار) للغة العربية
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,

        // **AppBar مع عكس اتجاه الأيقونات (سهم الرجوع يمين، اللغة يسار)**
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B36),
          foregroundColor: Colors.white,
          title: const Text(
            'إنشاء حساب سائق', // تم تحديث العنوان
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,

          // **Leading (اليسار): أيقونة اللغة**
          leading: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.language),
          ),

          // **Actions (اليمين): سهم الرجوع**
          actions: [
            IconButton(
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ), // سهم يشير لليمين (للخلف في RTL)
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // **أيقونة الدور (السائق) فوق الحقل الأول**
              const Icon(
                Icons.directions_bus, // أيقونة السائق
                size: 60,
                color: Color(0xFF0D47A1),
              ),
              const SizedBox(height: 10),

              // حقل الاسم الأول
              _buildLabeledTextField(
                labelText: 'الاسم الأول',
                hintText: 'أدخل الاسم الأول',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // حقل الاسم الأخير
              _buildLabeledTextField(
                labelText: 'الاسم الأخير',
                hintText: 'أدخل اسم العائلة',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // حقل رقم الهوية
              _buildLabeledTextField(
                labelText: 'رقم الهوية',
                hintText: 'أدخل رقم الهوية',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              _buildLabeledTextField(
                labelText: 'رقم الرخصة',
                hintText: 'أدخل رقم الرخصة',
                icon: Icons.credit_card, // أيقونة رخصة
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // *** حقل تاريخ الميلاد ***
              _buildLabeledTextField(
                labelText: 'تاريخ الميلاد',
                hintText: 'يوم / شهر / سنة',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 20),

              // حقل رقم الجوال
              _buildLabeledTextField(
                labelText: 'رقم الجوال',
                hintText: 'مثال: 05xxxxxxx',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // حقل البريد الإلكتروني
              _buildLabeledTextField(
                labelText: 'البريد الإلكتروني',
                hintText: 'example@domain.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // حقل كلمة المرور
              _buildLabeledTextField(
                labelText: 'كلمة المرور',
                hintText: 'كلمة مرور قوية',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              // *** حقل تأكيد كلمة المرور ***
              _buildLabeledTextField(
                labelText: 'تأكيد كلمة المرور',
                hintText: 'أعد إدخال كلمة المرور',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // زر التسجيل
              ElevatedButton(
                onPressed: () {
                  // منطق التسجيل
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BAA3C),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'تسجيل الآن',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
