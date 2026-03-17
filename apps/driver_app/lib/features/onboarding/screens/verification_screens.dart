import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_providers.dart';

class AadhaarVerificationScreen extends ConsumerStatefulWidget {
  const AadhaarVerificationScreen({super.key});

  @override
  ConsumerState<AadhaarVerificationScreen> createState() => _AadhaarVerificationScreenState();
}

class _AadhaarVerificationScreenState extends ConsumerState<AadhaarVerificationScreen> {
  final TextEditingController _aadhaarController = TextEditingController();
  Uint8List? _selfieBytes;
  String? _selfieFileName;
  bool _isLoading = false;

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selfieBytes = bytes;
        _selfieFileName = pickedFile.name;
      });
    }
  }

  Future<void> _verifyAndContinue() async {
    if (_aadhaarController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 12-digit Aadhaar number')),
      );
      return;
    }
    if (_selfieBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie for verification')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw 'User not authenticated';

      // Upload selfie
      final selfieUrl = await ref.read(storageServiceProvider).uploadDocument(
        userId: userId,
        docType: 'selfie',
        bytes: _selfieBytes!,
        fileName: _selfieFileName!,
      );

      final profileService = ref.read(profileServiceProvider);

      // Save Aadhaar data in 'drivers' table
      await profileService.updateDriverInfo(
        driverId: userId,
        updates: {
          'aadhaar_number': _aadhaarController.text,
          'verification_status': 'pending',
        },
      );

      // Save selfie record in 'driver_documents' table as 'aadhaar_front'
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'aadhaar_front',
        filePath: selfieUrl,
        metadata: {'type': 'selfie'},
      );

      if (mounted) {
        context.push('/dl-verification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2 of 7'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: 2/7,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aadhaar Verification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'To ensure safety, we verify your identity through Aadhaar.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildTextField('Aadhaar Number', _aadhaarController, hint: '12-digit number'),
            const SizedBox(height: 32),
            const Text(
              'Face Match',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                   if (_selfieBytes != null)
                     ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: Image.memory(_selfieBytes!, height: 120, width: 120, fit: BoxFit.cover),
                     )
                   else
                     const Icon(Icons.face_retouching_natural_rounded, size: 48, color: AppColors.primaryEmerald),
                   const SizedBox(height: 16),
                   Text(
                     _selfieBytes != null ? 'Selfie Captured' : 'Take a Selfie',
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                   ),
                   const SizedBox(height: 4),
                   const Text(
                     'Make sure your face is clearly visible',
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                   ),
                   const SizedBox(height: 24),
                   OutlinedButton(
                     onPressed: _takeSelfie,
                     style: OutlinedButton.styleFrom(
                       side: const BorderSide(color: AppColors.primaryEmerald),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: Text(_selfieBytes != null ? 'Retake Selfie' : 'Launch Camera', style: const TextStyle(color: AppColors.primaryEmerald)),
                   ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyAndContinue,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify & Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 12,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class DrivingLicenceScreen extends ConsumerStatefulWidget {
  const DrivingLicenceScreen({super.key});

  @override
  ConsumerState<DrivingLicenceScreen> createState() => _DrivingLicenceScreenState();
}

class _DrivingLicenceScreenState extends ConsumerState<DrivingLicenceScreen> {
  Uint8List? _frontBytes;
  String? _frontFileName;
  Uint8List? _backBytes;
  String? _backFileName;
  bool _isLoading = false;

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isFront) {
          _frontBytes = bytes;
          _frontFileName = pickedFile.name;
        } else {
          _backBytes = bytes;
          _backFileName = pickedFile.name;
        }
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_frontBytes == null || _backBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back sides of your DL')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw 'User not authenticated';

      final storage = ref.read(storageServiceProvider);
      final profileService = ref.read(profileServiceProvider);

      // Upload files
      final frontUrl = await storage.uploadDocument(
        userId: userId, 
        docType: 'dl', 
        bytes: _frontBytes!, 
        fileName: _frontFileName!,
      );
      final backUrl = await storage.uploadDocument(
        userId: userId, 
        docType: 'dl', 
        bytes: _backBytes!, 
        fileName: _backFileName!,
      );

      // Save documents in 'driver_documents' table independently
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'dl_front',
        filePath: frontUrl,
      );
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'dl_back',
        filePath: backUrl,
      );
      // dl_front and dl_back are already saved above.

      // Update driver info in 'drivers' table
      await profileService.updateDriverInfo(
        driverId: userId,
        updates: {
          'verification_status': 'pending',
        },
      );

      if (mounted) {
        context.push('/rc-verification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 3 of 7'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: 3/7,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driving Licence',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your valid Driving Licence (Front & Back).',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildUploadCard('DL Front Side', 'Make sure text is readable', _frontBytes, () => _pickImage(true)),
            const SizedBox(height: 20),
            _buildUploadCard('DL Back Side', 'Include address and valid dates', _backBytes, () => _pickImage(false)),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(String title, String subtitle, Uint8List? bytes, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bytes != null ? AppColors.primaryEmerald : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            if (bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: AppColors.primaryEmerald),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  Text(
                    bytes != null ? 'Image Selected' : subtitle,
                    style: TextStyle(fontSize: 12, color: bytes != null ? AppColors.primaryEmerald : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(bytes != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: bytes != null ? AppColors.primaryEmerald : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class RcVerificationScreen extends ConsumerStatefulWidget {
  const RcVerificationScreen({super.key});

  @override
  ConsumerState<RcVerificationScreen> createState() => _RcVerificationScreenState();
}

class _RcVerificationScreenState extends ConsumerState<RcVerificationScreen> {
  Uint8List? _frontBytes;
  String? _frontFileName;
  Uint8List? _backBytes;
  String? _backFileName;
  bool _isLoading = false;

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isFront) {
          _frontBytes = bytes;
          _frontFileName = pickedFile.name;
        } else {
          _backBytes = bytes;
          _backFileName = pickedFile.name;
        }
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_frontBytes == null || _backBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back sides of your RC')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw 'User not authenticated';

      final storage = ref.read(storageServiceProvider);
      final profileService = ref.read(profileServiceProvider);

      // Upload files
      final frontUrl = await storage.uploadDocument(
        userId: userId, 
        docType: 'rc', 
        bytes: _frontBytes!, 
        fileName: _frontFileName!,
      );
      final backUrl = await storage.uploadDocument(
        userId: userId, 
        docType: 'rc', 
        bytes: _backBytes!, 
        fileName: _backFileName!,
      );

      // Save documents in 'driver_documents' table independently
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'rc_front',
        filePath: frontUrl,
      );
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'rc_back',
        filePath: backUrl,
      );

      // Update driver info
      await profileService.updateDriverInfo(
        driverId: userId,
        updates: {
          'verification_status': 'pending',
        },
      );

      if (mounted) {
        context.push('/vehicle-images');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 4 of 7'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: 4/7,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Registration (RC)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your Vehicle Registration Certificate.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildUploadCard('RC Front Side', 'Make sure registration number is visible', _frontBytes, () => _pickImage(true)),
            const SizedBox(height: 20),
            _buildUploadCard('RC Back Side', 'Include vehicle details and owner info', _backBytes, () => _pickImage(false)),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(String title, String subtitle, Uint8List? bytes, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bytes != null ? AppColors.primaryEmerald : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            if (bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: AppColors.primaryEmerald),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  Text(
                    bytes != null ? 'Image Selected' : subtitle,
                    style: TextStyle(fontSize: 12, color: bytes != null ? AppColors.primaryEmerald : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(bytes != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: bytes != null ? AppColors.primaryEmerald : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class VehicleImagesScreen extends ConsumerStatefulWidget {
  const VehicleImagesScreen({super.key});

  @override
  ConsumerState<VehicleImagesScreen> createState() => _VehicleImagesScreenState();
}

class _VehicleImagesScreenState extends ConsumerState<VehicleImagesScreen> {
  final Map<String, Uint8List?> _vehicleBytes = {
    'Front View': null,
    'Rear View': null,
    'Left Side': null,
    'Right Side': null,
    'Interior (Front)': null,
    'Interior (Back)': null,
  };
  final Map<String, String?> _vehicleFileNames = {
    'Front View': null,
    'Rear View': null,
    'Left Side': null,
    'Right Side': null,
    'Interior (Front)': null,
    'Interior (Back)': null,
  };
  bool _isLoading = false;

  Future<void> _pickImage(String label) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _vehicleBytes[label] = bytes;
        _vehicleFileNames[label] = pickedFile.name;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_vehicleBytes.values.any((f) => f == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all 6 vehicle photos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw 'User not authenticated';

      final storage = ref.read(storageServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final List<String> photoUrls = [];

      for (var label in _vehicleBytes.keys) {
        final url = await storage.uploadDocument(
          userId: userId, 
          docType: 'vehicle_photo', 
          bytes: _vehicleBytes[label]!,
          fileName: _vehicleFileNames[label]!,
        );
        photoUrls.add(url);
      }

      // Save as one 'vehicle_photo' document with all URLs in metadata
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'vehicle_photo',
        filePath: photoUrls.first, // Front View
        metadata: {
          'all_photos': photoUrls,
          'labels': _vehicleBytes.keys.toList(),
        },
      );

      // Also update vehicle photo_url in 'vehicles' table
      final vehicles = await profileService.getVehicles(userId);
      if (vehicles.isNotEmpty) {
        await profileService.updateVehicle(
          vehicleId: vehicles.first['id'], 
          updates: {
            'photo_url': photoUrls.first,
          }
        );
      }

      await profileService.updateDriverInfo(
        driverId: userId,
        updates: {
          'verification_status': 'pending',
        },
      );

      if (mounted) {
        context.push('/insurance-puc');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 5 of 7'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: 5/7,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Images',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload clear photos of your vehicle from different angles.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: _vehicleBytes.keys.map((label) => _buildImageUploadCard(label)).toList(),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadCard(String label) {
    final bytes = _vehicleBytes[label];
    return GestureDetector(
      onTap: () => _pickImage(label),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bytes != null ? AppColors.primaryEmerald : Colors.white.withValues(alpha: 0.05)),
          image: bytes != null ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover) : null,
        ),
        child: bytes == null ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_rounded, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ) : null,
      ),
    );
  }
}

class InsurancePucScreen extends ConsumerStatefulWidget {
  const InsurancePucScreen({super.key});

  @override
  ConsumerState<InsurancePucScreen> createState() => _InsurancePucScreenState();
}

class _InsurancePucScreenState extends ConsumerState<InsurancePucScreen> {
  Uint8List? _insuranceBytes;
  String? _insuranceFileName;
  Uint8List? _pucBytes;
  String? _pucFileName;
  bool _isLoading = false;

  Future<void> _pickImage(bool isInsurance) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isInsurance) {
          _insuranceBytes = bytes;
          _insuranceFileName = pickedFile.name;
        } else {
          _pucBytes = bytes;
          _pucFileName = pickedFile.name;
        }
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_insuranceBytes == null || _pucBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both Insurance and PUC certificates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw 'User not authenticated';

      final storage = ref.read(storageServiceProvider);
      final profileService = ref.read(profileServiceProvider);

      // Upload files
      final insuranceUrl = await storage.uploadDocument(
        userId: userId, 
        docType: 'insurance', 
        bytes: _insuranceBytes!, 
        fileName: _insuranceFileName!,
      );
      final pucUrl = await storage.uploadDocument(
        userId: userId, 
        docType: 'puc', 
        bytes: _pucBytes!, 
        fileName: _pucFileName!,
      );

      // Save documents in 'driver_documents' table
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'insurance',
        filePath: insuranceUrl,
      );
      await profileService.updateDriverDoc(
        driverId: userId,
        docType: 'puc',
        filePath: pucUrl,
      );

      // Update driver info
      await profileService.updateDriverInfo(
        driverId: userId,
        updates: {
          'verification_status': 'pending',
        },
      );

      if (mounted) {
        context.push('/bank-details');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 6 of 7'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: 6/7,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insurance & PUC',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload valid insurance and Pollution Under Control (PUC) certificates.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildUploadCard('Vehicle Insurance', 'Valid for at least 3 months', _insuranceBytes, () => _pickImage(true)),
            const SizedBox(height: 20),
            _buildUploadCard('PUC Certificate', 'Pollution Control Certificate', _pucBytes, () => _pickImage(false)),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(String title, String subtitle, Uint8List? bytes, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bytes != null ? AppColors.primaryEmerald : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            if (bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: AppColors.primaryEmerald),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  Text(
                    bytes != null ? 'Image Selected' : subtitle,
                    style: TextStyle(fontSize: 12, color: bytes != null ? AppColors.primaryEmerald : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(bytes != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: bytes != null ? AppColors.primaryEmerald : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final TextEditingController _accNumController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitApplication() async {
    if (_accNumController.text.isEmpty || _ifscController.text.isEmpty || _holderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all bank details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw 'User not authenticated';

      final profileService = ref.read(profileServiceProvider);

      // Update bank details in 'bank_details' table
      await profileService.updateBankDetails(
        userId: userId,
        bankData: {
          'account_holder_name': _holderController.text,
          'account_number': _accNumController.text,
          'ifsc_code': _ifscController.text,
        },
      );

      // Final status update in 'drivers'
      await profileService.updateDriverInfo(
        driverId: userId,
        updates: {
          'verification_status': 'pending',
        },
      );

      if (mounted) {
        context.push('/verification-pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 7 of 7'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: 7/7,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payout Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your bank details to receive earnings from your rides.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildTextField('Account Holder Name', _holderController, hint: 'As per Bank Records'),
            const SizedBox(height: 20),
            _buildTextField('Account Number', _accNumController, hint: 'Bank account number'),
            const SizedBox(height: 20),
            _buildTextField('IFSC Code', _ifscController, hint: 'HDFC0001234'),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitApplication,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Application'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  ConsumerState<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends ConsumerState<VerificationPendingScreen> {
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    _subscription = ref.read(supabaseClientProvider)
        .channel('public:drivers:id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'drivers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['verification_status'];
            if (newStatus == 'verified' && mounted) {
              context.go('/main');
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_subscription != null) {
      ref.read(supabaseClientProvider).removeChannel(_subscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: AppColors.primaryEmerald,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Verification in Progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our team is reviewing your documents. This usually takes 24–48 hours. We’ll notify you once you’re ready to start driving!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 80),
            OutlinedButton(
              onPressed: () {
                context.go('/splash');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryEmerald),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Done',
                style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
