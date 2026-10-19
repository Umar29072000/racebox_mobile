import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/models/vehicle_profile.dart';
import '../bloc/timer/race_timer_bloc.dart';
import '../bloc/timer/race_timer_event.dart';
import '../bloc/vehicle/vehicle_bloc.dart';
import '../bloc/vehicle/vehicle_event.dart';
import '../bloc/vehicle/vehicle_state.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(LoadVehicles());
  }

  void _showAddVehicleDialog(BuildContext context, [VehicleProfile? existing]) {
    final nameController = TextEditingController(text: existing?.vehicleName ?? '');
    final weightController = TextEditingController(
      text: existing != null ? existing.kerbWeightKg.toString() : '115.0',
    );
    final noteController = TextEditingController(text: existing?.sprocketOrRollerNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            existing == null ? 'TAMBAH PROFIL MOTOR' : 'EDIT PROFIL MOTOR',
            style: const TextStyle(
              color: AppColors.cyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nama Motor / Kendaraan',
                    hintText: 'misal: Vario 160 Bore-Up',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Bobot Motor (kg)',
                    hintText: '118.0',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Catatan Roller / CVT / Gir',
                    hintText: 'misal: Roller 11gr, Per CVT 1500, Gir 14/42',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final weight = double.tryParse(weightController.text) ?? 115.0;
                final notes = noteController.text.trim();

                if (name.isNotEmpty) {
                  final vehicle = VehicleProfile(
                    id: existing?.id ?? const Uuid().v4(),
                    vehicleName: name,
                    kerbWeightKg: weight,
                    sprocketOrRollerNote: notes,
                    isDefault: existing?.isDefault ?? false,
                  );

                  context.read<VehicleBloc>().add(SaveVehicleProfile(vehicle));
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'GARASI & PROFIL MOTOR',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.black,
        onPressed: () => _showAddVehicleDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
          }

          if (state is VehicleError) {
            return Center(
              child: Text(state.message, style: const TextStyle(color: AppColors.red)),
            );
          }

          if (state is VehicleLoaded) {
            if (state.vehicles.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada motor di garasi. Tambahkan sekarang!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.vehicles.length,
              itemBuilder: (context, index) {
                final v = state.vehicles[index];
                final isDefault = v.isDefault;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isDefault ? AppColors.cyan : AppColors.border,
                      width: isDefault ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.two_wheeler,
                                color: isDefault ? AppColors.cyan : AppColors.textSecondary,
                                size: 22.0,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                v.vehicleName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: AppColors.cyan),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Bobot: ${v.kerbWeightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.0,
                        ),
                      ),
                      if (v.sprocketOrRollerNote.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          'Settingan: ${v.sprocketOrRollerNote}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isDefault)
                            TextButton(
                              onPressed: () {
                                context.read<VehicleBloc>().add(SetDefaultVehicleEvent(v.id));
                                context.read<RaceTimerBloc>().add(SetActiveVehicle(v));
                              },
                              child: const Text('PILIH SEBAGAI AKTIF', style: TextStyle(color: AppColors.cyan)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18.0, color: AppColors.textSecondary),
                            onPressed: () => _showAddVehicleDialog(context, v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18.0, color: AppColors.red),
                            onPressed: () {
                              context.read<VehicleBloc>().add(DeleteVehicleProfile(v.id));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
