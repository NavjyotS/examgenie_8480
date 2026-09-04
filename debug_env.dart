// debug_env.dart
import 'dart:io';

void main() {
  print('=============================================');
  print('          ENVied PATH DIAGNOSTIC             ');
  print('=============================================\n');

  // 1. Get the current working directory of the project
  final currentDir = Directory.current;
  print('📁 Project Root Directory Path:\n   ${currentDir.path}\n');

  // 2. Look for .env file explicitly
  final envFile = File('${currentDir.path}/.env');
  print('🔍 Checking for .env file...');
  
  if (!envFile.existsSync()) {
    print('❌ ERROR: .env file NOT FOUND at this path!\n');
    print('📂 Here are the files present in your root directory:');
    for (var entity in currentDir.listSync()) {
      print('  - ${entity.path.split(Platform.pathSeparator).last}');
    }
    return;
  }

  print('✅ SUCCESS: .env file located.\n');

  // 3. Read and inspect file contents safely without exposing the full key
  print('📄 Inspecting .env content line by line:');
  final lines = envFile.readAsLinesSync();
  
  if (lines.isEmpty) {
    print('⚠️ WARNING: Your .env file is empty!');
    return;
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue; // Skip comments/empty lines

    final parts = line.split('=');
    final key = parts[0].trim();
    
    if (key == 'API_KEY') {
      final value = parts.length > 1 ? parts.sublist(1).join('=') : '';
      print('  Line ${i + 1}: Found match -> [KEY]: "$key" | [VALUE LENGTH]: ${value.length} characters');
    } else {
      print('  Line ${i + 1}: Found key -> "$key" (Does not match exact target "API_KEY")');
    }
  }
  print('\n=============================================');
}
