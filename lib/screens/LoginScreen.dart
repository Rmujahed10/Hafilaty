import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for filtering input (e.g., digits only)

// 1. Change to StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to manage the input text from the fields
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Clean up controllers when the widget is disposed
  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 // lib/screens/login_screen.dart (Around line 29)

  @override
  Widget build(BuildContext context) {
    // REMOVE 'const' keyword here
    return Scaffold(
      // We remove the AppBar because the title is part of the custom header design
      body: _buildBody(), 
    );
  }

  // --- UI Layout Implementation ---

  Widget _buildBody() {
    // 2. Use a Stack to layer the dark background and the white card
    return Stack(
      children: <Widget>[
        // Dark Navy Blue Background (Top Half)
        Container(
          height: MediaQuery.of(context).size.height * 0.4, // Occupies top 40%
          color: const Color(0xFF0D1B36), // Use a deep blue color
        ),
        
        // Login Card and Content (Center)
        Center(
          child: SingleChildScrollView( // Allows scrolling if the content is long
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // "تسجيل الدخول" Header text on the dark background
                const Padding(
                  padding: EdgeInsets.only(bottom: 40.0),
                  child: Text(
                    'تسجيل الدخول', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // The White Login Card/Container
                _buildLoginCard(),

                // Sign up link (outside the card)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to SignupScreen
                  },
                  child: const Text(
                    'تسجيل حساب جديد',
                    style: TextStyle(color: Color(0xFF0D1B36)), // Dark text color
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper function to build the white card content
  Widget _buildLoginCard() {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            // The HAFILATY Logo Image (Placeholder)
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Image.asset(
                'assets/hafilaty_logo.png', // NOTE: Ensure this asset is registered in pubspec.yaml
                height: 50,
              ),
            ),
            
            // Phone Number Field (Corrected Call)
            _buildInputField(
              'رقم الجوال',
              _phoneController,
              Icons.phone,
              TextInputType.phone, // 4th Positional Argument
            ),
            
            const SizedBox(height: 20),

            // Password Field (Corrected Call)
            _buildInputField(
              'كلمة المرور',
              _passwordController,
              Icons.lock,
              TextInputType.text, // 4th Positional Argument (using default text keyboard)
              isPassword: true,
            ),

            // "هل نسيت كلمة المرور؟" link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('هل نسيت كلمة المرور؟'),
              ),
            ),

            const SizedBox(height: 10),

            // Gradient Login Button
            _buildLoginButton(),

            const SizedBox(height: 20),

            // Language Switcher
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('اللغة / Language'),
                SizedBox(width: 8),
                Icon(Icons.language),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Reusable function to create the rounded input fields
  // IMPORTANT FIX: TextInputType is now the 4th required POSITIONAL argument
  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData suffixIcon,
    TextInputType keyboardType, // NOW POSITIONAL
    {bool isPassword = false} // isPassword is still a NAMED argument
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF6A994E), fontWeight: FontWeight.bold), // Using the green color from your design
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword, // Hides text for password fields
          textAlign: TextAlign.right, // Align text right for Arabic input
          // Optional: Restrict phone input to digits only
          inputFormatters: keyboardType == TextInputType.phone ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0), // Rounded corners
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200], // Light grey background
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            suffixIcon: Icon(suffixIcon, color: Colors.grey[600]), // The icon inside the field
          ),
        ),
      ],
    );
  }
  
  // Function to create the gradient button
  Widget _buildLoginButton() {
    return Container(
      width: double.infinity, // Full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // Define the gradient colors based on your image
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1B36), // Dark Blue (start)
            Color(0xFF6A994E), // Greenish (end)
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement login logic (e.g., API call)
          debugPrint('Phone: ${_phoneController.text}, Password: ${_passwordController.text}');
        },
        style: ElevatedButton.styleFrom(
          // Important: Set background color to transparent to show the Container's gradient
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent, // Remove shadow
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'تسجيل الدخول',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}