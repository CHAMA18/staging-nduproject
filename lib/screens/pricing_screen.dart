import 'package:flutter/material.dart';
import 'package:ndu_project/screens/management_level_screen.dart';
import 'package:ndu_project/services/subscription_service.dart';
import 'package:ndu_project/widgets/payment_dialog.dart';

const Color _pageBackground = Color(0xFFF5F6F8);
const Color _primaryText = Color(0xFF0F0F0F);
const Color _secondaryText = Color(0xFF5A5C60);
const Color _themeColor = Color(0xFFF4B400); // Unified golden theme
const Color _themeSurface = Color(0xFFFFF7E6); // Soft warm backdrop

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  _PlanTier _selectedTier = _PlanTier.program;
  bool _isCheckingSubscription = false;

  Future<void> _handlePlanSelection(BuildContext context, _PricingPlan plan) async {
    setState(() => _isCheckingSubscription = true);
    
    try {
      final subscriptionTier = _convertToSubscriptionTier(plan.tier);
      final hasSubscription = await SubscriptionService.hasActiveSubscription(tier: subscriptionTier);
      
      if (!mounted) return;
      
      if (hasSubscription) {
        _navigateToManagementLevel(context);
      } else {
        final paymentResult = await PaymentDialog.show(
          context: context,
          tier: subscriptionTier,
          isAnnual: true,
          onPaymentComplete: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription activated successfully!'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            }
          },
        );
        
        if (paymentResult && mounted) {
          _navigateToManagementLevel(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking subscription: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCheckingSubscription = false);
    }
  }
  
  SubscriptionTier _convertToSubscriptionTier(_PlanTier tier) {
    switch (tier) {
      case _PlanTier.basicProject:
        return SubscriptionTier.project;
      case _PlanTier.project:
        return SubscriptionTier.project;
      case _PlanTier.program:
        return SubscriptionTier.program;
      case _PlanTier.portfolio:
        return SubscriptionTier.portfolio;
    }
  }
  
  void _navigateToManagementLevel(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagementLevelScreen()));
  }

  static const List<_PricingPlan> _plans = [
    _PricingPlan(
      tier: _PlanTier.basicProject,
      label: 'Basic Project',
      badgeColor: _themeColor,
      subtitle: 'No Fuss routine project delivered at a fraction of the cost',
      features: [
        'One time Freemium for the 1st month',
        'Monthly payment with annual discount.',
        '1 user',
        'Limited AI features',
        'Any email or School email only (special domain. No gmail, yahoo, outlook, etc.) No other free trial for that domain.',
        'Limited AI incorporation (prompt to upgrade after 1st implementation)',
        'Can be upgraded to others at any time and details get immediately carried forward to full project',
      ],
    ),
    _PricingPlan(
      tier: _PlanTier.project,
      label: 'Project',
      badgeColor: _themeColor,
      subtitle: 'Robust project delivered at an affordable rate',
      features: [
        'Subscription Based.',
        'Maximum 7 users',
        'Monthly. Annual at a discount.',
        'Access to completed project pdfs when done with each project.',
        'Can upgrade anytime to other levels.',
        'Can\'t downgrade any active project until that actual project is completed.',
        'Can add new project, program and portfolio to the account',
        'Once project is completed, new project could be at another level.',
        'Business email or School email (special domain. No gmail, yahoo, outlook, etc.) No other free trial for that domain.',
        'Promocode can be applied to payment.',
      ],
    ),
    _PricingPlan(
      tier: _PlanTier.program,
      label: 'Program',
      badgeColor: _themeColor,
      subtitle: 'Up to 3 projects at a discounted rate with interface management',
      features: [
        'Subscription Based.',
        'Maximum 12 users',
        'Monthly. Annual at a discount.',
        'Access to completed project pdfs when done with each project, and at program level.',
        'Can upgrade anytime to portfolio.',
        'Can\'t downgrade any active project within a program once started. All identified projects within a program stays until the program is completed.',
        'Can add new project, program and portfolio to the account',
        'Business email or School email (special domain. No gmail, yahoo, outlook, etc.) No other free trial for that domain.',
        'Promocode can be applied to payment.',
      ],
    ),
    _PricingPlan(
      tier: _PlanTier.portfolio,
      label: 'Portfolio',
      badgeColor: _themeColor,
      subtitle: 'Up to 9 projects at a bulk rate with integrated stewarding',
      features: [
        'Subscription Based.',
        'Maximum 24 users',
        'Monthly. Annual at a discount.',
        'Access to completed project pdfs when done with each project/program.',
        'Can\'t downgrade any active project or program once started. All identified projects within a program stays until the program is completed.',
        'Can add new project, program and portfolio to the account',
        'Business email or School email (special domain. No gmail, yahoo, outlook, etc.) No other free trial for that domain.',
        'Promocode can be applied to payment.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;
    final isTablet = size.width >= 800 && size.width < 1200;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : (isTablet ? 32 : 16),
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(context),
              const SizedBox(height: 32),
              // Payment Structure title
              const Text(
                'Payment Structure',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              // Plans grid
              _buildPlansGrid(isDesktop, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        _BackButton(onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.maybePop();
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
            );
          }
        }),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Select a plan that fits your needs',
            style: TextStyle(color: _secondaryText, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPlansGrid(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      // 4 columns on desktop
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _plans.map((plan) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _PlanColumn(
              plan: plan,
              isSelected: _selectedTier == plan.tier,
              onSelect: () {
                setState(() => _selectedTier = plan.tier);
                _handlePlanSelection(context, plan);
              },
            ),
          ),
        )).toList(),
      );
    } else if (isTablet) {
      // 2x2 grid on tablet
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Padding(
                padding: const EdgeInsets.all(8),
                child: _PlanColumn(
                  plan: _plans[0],
                  isSelected: _selectedTier == _plans[0].tier,
                  onSelect: () {
                    setState(() => _selectedTier = _plans[0].tier);
                    _handlePlanSelection(context, _plans[0]);
                  },
                ),
              )),
              Expanded(child: Padding(
                padding: const EdgeInsets.all(8),
                child: _PlanColumn(
                  plan: _plans[1],
                  isSelected: _selectedTier == _plans[1].tier,
                  onSelect: () {
                    setState(() => _selectedTier = _plans[1].tier);
                    _handlePlanSelection(context, _plans[1]);
                  },
                ),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Padding(
                padding: const EdgeInsets.all(8),
                child: _PlanColumn(
                  plan: _plans[2],
                  isSelected: _selectedTier == _plans[2].tier,
                  onSelect: () {
                    setState(() => _selectedTier = _plans[2].tier);
                    _handlePlanSelection(context, _plans[2]);
                  },
                ),
              )),
              Expanded(child: Padding(
                padding: const EdgeInsets.all(8),
                child: _PlanColumn(
                  plan: _plans[3],
                  isSelected: _selectedTier == _plans[3].tier,
                  onSelect: () {
                    setState(() => _selectedTier = _plans[3].tier);
                    _handlePlanSelection(context, _plans[3]);
                  },
                ),
              )),
            ],
          ),
        ],
      );
    } else {
      // Single column on mobile
      return Column(
        children: _plans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _PlanColumn(
            plan: plan,
            isSelected: _selectedTier == plan.tier,
            onSelect: () {
              setState(() => _selectedTier = plan.tier);
              _handlePlanSelection(context, plan);
            },
          ),
        )).toList(),
      );
    }
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back, color: _secondaryText, size: 20),
        ),
      ),
    );
  }
}

class _PlanColumn extends StatelessWidget {
  const _PlanColumn({
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  final _PricingPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final Color accent = _themeColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            _themeSurface,
            Colors.white,
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSelected ? accent : Colors.black12,
          width: isSelected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
          if (isSelected)
            BoxShadow(
              color: accent.withOpacity(0.14),
              blurRadius: 26,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Text(
                  plan.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: _themeColor, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Chosen',
                        style: TextStyle(
                          color: _themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.subtitle,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 16),
          ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? accent : Colors.white,
                foregroundColor: isSelected ? Colors.white : accent,
                elevation: isSelected ? 8 : 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accent, width: 1.4),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                shadowColor: accent.withOpacity(isSelected ? 0.3 : 0.15),
              ),
              child: Text(isSelected ? 'Selected' : 'Select Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingPlan {
  const _PricingPlan({
    required this.tier,
    required this.label,
    required this.badgeColor,
    required this.subtitle,
    required this.features,
  });

  final _PlanTier tier;
  final String label;
  final Color badgeColor;
  final String subtitle;
  final List<String> features;
}

enum _PlanTier { basicProject, project, program, portfolio }
