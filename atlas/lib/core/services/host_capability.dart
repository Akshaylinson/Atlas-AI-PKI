import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class HostCapabilityProfile {
  final String os;
  final String architecture;
  final int cpuCores;
  final double ramGb;
  final bool gpuAvailable;
  final String gpuType;
  final String aiRuntime;

  const HostCapabilityProfile({
    required this.os,
    required this.architecture,
    required this.cpuCores,
    required this.ramGb,
    required this.gpuAvailable,
    required this.gpuType,
    required this.aiRuntime,
  });

  Map<String, dynamic> toJson() => {
        'os': os,
        'architecture': architecture,
        'cpu_cores': cpuCores,
        'ram_gb': ramGb,
        'gpu_available': gpuAvailable,
        'gpu_type': gpuType,
        'ai_runtime': aiRuntime,
      };

  static Future<HostCapabilityProfile> detect() async {
    final plugin = DeviceInfoPlugin();
    String os = Platform.operatingSystem;
    String architecture = 'unknown';
    int cpuCores = Platform.numberOfProcessors;
    double ramGb = 0.0;
    bool gpuAvailable = false;
    String gpuType = 'unknown';
    String aiRuntime = 'flutter_gemma';

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      architecture = info.supportedAbis.isNotEmpty ? info.supportedAbis.first : 'arm64';
      gpuAvailable = true;
      gpuType = 'Android GPU';
      aiRuntime = 'flutter_gemma';
    } else if (Platform.isLinux) {
      architecture = _detectLinuxArch();
      ramGb = await _detectLinuxRam();
      gpuAvailable = await _detectLinuxGpu();
      gpuType = gpuAvailable ? await _detectLinuxGpuType() : 'none';
      aiRuntime = gpuAvailable ? 'llama_cpp_cuda' : 'llama_cpp_cpu';
    } else if (Platform.isWindows) {
      architecture = 'x86_64';
      aiRuntime = 'llama_cpp_cpu';
    } else if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      architecture = info.arch;
      aiRuntime = 'llama_cpp_metal';
    }

    return HostCapabilityProfile(
      os: os,
      architecture: architecture,
      cpuCores: cpuCores,
      ramGb: ramGb,
      gpuAvailable: gpuAvailable,
      gpuType: gpuType,
      aiRuntime: aiRuntime,
    );
  }

  static String _detectLinuxArch() {
    try {
      final result = Process.runSync('uname', ['-m']);
      return result.stdout.toString().trim();
    } catch (_) {
      return 'x86_64';
    }
  }

  static Future<double> _detectLinuxRam() async {
    try {
      final result = await Process.run('grep', ['MemTotal', '/proc/meminfo']);
      final line = result.stdout.toString().trim();
      final match = RegExp(r'(\d+)').firstMatch(line);
      if (match != null) {
        final kb = int.tryParse(match.group(1) ?? '0') ?? 0;
        return kb / (1024 * 1024);
      }
    } catch (_) {}
    return 0.0;
  }

  static Future<bool> _detectLinuxGpu() async {
    try {
      final result = await Process.run('which', ['nvidia-smi']);
      if (result.exitCode == 0) return true;
      final lspci = await Process.run('lspci', []);
      final out = lspci.stdout.toString().toLowerCase();
      return out.contains('vga') || out.contains('3d') || out.contains('display');
    } catch (_) {
      return false;
    }
  }

  static Future<String> _detectLinuxGpuType() async {
    try {
      final result = await Process.run('which', ['nvidia-smi']);
      if (result.exitCode == 0) return 'NVIDIA';
      final lspci = await Process.run('lspci', []);
      final out = lspci.stdout.toString().toLowerCase();
      if (out.contains('amd') || out.contains('radeon')) return 'AMD';
      if (out.contains('intel')) return 'Intel';
    } catch (_) {}
    return 'unknown';
  }

  static Future<bool> detectVulkan() async {
    try {
      // vulkaninfo exits 0 when Vulkan is available
      final r = await Process.run('vulkaninfo', ['--summary'],
          runInShell: true);
      return r.exitCode == 0;
    } catch (_) {}
    try {
      // Fallback: check if the Vulkan loader library is present
      return File('/usr/lib/x86_64-linux-gnu/libvulkan.so.1').existsSync() ||
          File('/usr/lib/libvulkan.so.1').existsSync();
    } catch (_) {
      return false;
    }
  }
}
