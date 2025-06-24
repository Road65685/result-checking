Appwrite Functions with Dart
Appwrite Functions allow you to run server-side code in response to events (like a new user signing up, a document being created, or on a schedule) or by direct HTTP request. You can write these functions in various languages, including Dart.

How it Works
Write your Dart code: Your Dart function will receive input via environment variables (APPWRITE_FUNCTION_DATA) or stdin (for POST requests).

Process the data: Perform any logic, calculations, or external API calls.

Return JSON: The function should print its output to stdout. Appwrite automatically captures this output. If it's valid JSON, Appwrite will treat it as a JSON response.

Example Dart Function
Let's create a simple Dart function that takes a name as input, processes it (e.g., adds a greeting), and returns a JSON object.

// main.dart
import 'dart:io';
import 'dart:convert'; // Required for JSON encoding

void main() {
  // Read the request data from the environment variable (for GET/CLI invocation)
  // or from stdin (for POST requests with a body).
  // Appwrite typically passes data for GET/CLI via APPWRITE_FUNCTION_DATA.
  // For POST requests, the body is piped to stdin.

  String? inputData;

  // Try to read from APPWRITE_FUNCTION_DATA environment variable first
  inputData = Platform.environment['APPWRITE_FUNCTION_DATA'];

  // If not found in environment, try reading from stdin (for POST requests)
  if (inputData == null || inputData.isEmpty) {
    try {
      inputData = stdin.readLineSync();
    } catch (e) {
      // Handle error if stdin cannot be read
      stderr.writeln('Error reading from stdin: $e');
      inputData = '{}'; // Default to empty JSON
    }
  }

  Map<String, dynamic> requestPayload = {};
  if (inputData != null && inputData.isNotEmpty) {
    try {
      requestPayload = json.decode(inputData) as Map<String, dynamic>;
    } catch (e) {
      stderr.writeln('Error parsing input JSON: $e');
      requestPayload = {'error': 'Invalid JSON input'};
    }
  }

  String name = requestPayload['name'] ?? 'World';
  int number = requestPayload['number'] ?? 0;

  // Perform some processing
  String greeting = 'Hello, $name! You provided the number: ${number * 2}.';
  
  Map<String, dynamic> response = {
    'message': greeting,
    'originalName': name,
    'processedNumber': number * 2,
    'timestamp': DateTime.now().toIso8601String(),
    'status': 'success'
  };

  // Encode the response map to a JSON string and print it to stdout.
  // Appwrite captures this stdout as the function's response.
  stdout.writeln(json.encode(response));
}

Explanation of the Dart Code:
import 'dart:io';: Used to access Platform.environment for reading environment variables and stdin/stdout for input/output.

import 'dart:convert';: Essential for encoding Dart objects into JSON strings (json.encode) and decoding JSON strings into Dart objects (json.decode).

main() function: This is the entry point for your Dart function.

Reading Input: The code attempts to read input from APPWRITE_FUNCTION_DATA (typical for GET requests or CLI execution) or stdin (for POST request bodies). It then parses this input as JSON.

Processing: Simple string concatenation and multiplication are performed.

Returning JSON: A Dart Map<String, dynamic> is created with the desired output data. This map is then converted into a JSON string using json.encode() and printed to stdout using stdout.writeln(). Appwrite will then send this as the HTTP response.

Deploying to Appwrite
To deploy this function to Appwrite:

Save the file: Save the code above as main.dart in a new directory (e.g., my_dart_function).

Initialize Appwrite Function: Use the Appwrite CLI to initialize a new function in your project, selecting Dart as the runtime.

Upload: Deploy your function using the Appwrite CLI.

Configure: Set up variables, execution permissions, and events (if any) in the Appwrite console.

When you execute this function (e.g., via a direct HTTP request using the Appwrite SDK or API), it will return a JSON response similar to this:

{
  "message": "Hello, John Doe! You provided the number: 200.",
  "originalName": "John Doe",
  "processedNumber": 200,
  "timestamp": "2025-06-24T11:30:00.000Z",
  "status": "success"
}
