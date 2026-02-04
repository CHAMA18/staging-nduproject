import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ndu_project/providers/app_content_provider.dart';
import 'package:ndu_project/screens/create_account_screen.dart';
import 'package:ndu_project/screens/pricing_screen.dart';
import 'package:ndu_project/screens/sign_in_screen.dart';
import 'package:ndu_project/services/access_policy.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final ScrollController _scrollController;

  final GlobalKey _platformKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();
  final GlobalKey _aiKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  // Debug mode state
  bool _isDebugMode = false;
  int _kazAiTapCount = 0;
  DateTime? _lastKazAiTap;

  // Workflow tap counter for admin edit mode (admin domain only)
  int _workflowTapCount = 0;
  DateTime? _lastWorkflowTap;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _scrollController = ScrollController();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleKazAiTap() {
    final now = DateTime.now();
    // Reset counter if more than 2 seconds have passed
    if (_lastKazAiTap == null ||
        now.difference(_lastKazAiTap!) > const Duration(seconds: 2)) {
      _kazAiTapCount = 1;
    } else {
      _kazAiTapCount++;
    }
    _lastKazAiTap = now;

    if (_kazAiTapCount >= 4) {
      setState(() {
        _isDebugMode = !_isDebugMode;
        _kazAiTapCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isDebugMode
              ? '🛠️ Debug mode enabled'
              : '✅ Debug mode disabled'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Still scroll to AI section
      _scrollTo(_aiKey);
    }
  }

  void _handleWorkflowTap() {
    // Only enable edit mode on admin domain
    if (!AccessPolicy.isRestrictedAdminHost()) {
      // Not on admin domain, just scroll
      _scrollTo(_workflowKey);
      return;
    }

    final now = DateTime.now();
    // Reset counter if more than 2 seconds have passed
    if (_lastWorkflowTap == null ||
        now.difference(_lastWorkflowTap!) > const Duration(seconds: 2)) {
      _workflowTapCount = 1;
    } else {
      _workflowTapCount++;
    }
    _lastWorkflowTap = now;

    if (_workflowTapCount >= 5) {
      // Enable edit mode via provider
      final provider = context.read<AppContentProvider>();
      provider.toggleEditMode();

      setState(() => _workflowTapCount = 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.isEditMode
              ? '✏️ Edit mode enabled'
              : '✅ Edit mode disabled'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Still scroll to workflow section
      _scrollTo(_workflowKey);
    }
  }

  void _handleStartProject() {
    if (_isDebugMode) {
      // Allow navigation to pricing in debug mode
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PricingScreen()),
      );
    } else {
      // Show coming soon dialog with Typeform link
      _showComingSoonDialog();
    }
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LightModeColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 48,
                  color: LightModeColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'While we are actively consulting and helping companies drive profits through strong project delivery, we are also finalizing our project delivery platform for broader access. Join our waitlist to be notified when we launch.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchExternalLink('https://forms.gle/K6dvU4T9fi7FGxhg9');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LightModeColors.accent,
                    foregroundColor: const Color(0xFF151515),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Join Waitlist',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchExternalLink(String url) async {
    final uri = Uri.parse(url);
    final bool launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 1200;
    final bool isTablet = size.width >= 900 && size.width < 1200;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF040404),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -200,
                right: -120,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        LightModeColors.accent.withValues(alpha: 0.38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -260,
                left: -120,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              ScrollConfiguration(
                behavior: _NoGlowScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      SizedBox(height: isDesktop ? 140 : 110),
                      _buildHeroSection(context, isDesktop),
                      SizedBox(height: isDesktop ? 80 : 60),
                      _buildMomentumStrip(isDesktop),
                      SizedBox(height: isDesktop ? 80 : 60),
                      _buildPlatformSection(context, isDesktop || isTablet),
                      SizedBox(height: isDesktop ? 80 : 56),
                      _buildWorkflowSection(context, isDesktop || isTablet),
                      SizedBox(height: isDesktop ? 80 : 56),
                      _buildKazAISection(context, isDesktop),
                      SizedBox(height: isDesktop ? 80 : 56),
                      _buildCTASection(context, isDesktop),
                      SizedBox(height: isDesktop ? 80 : 56),
                      _buildFAQSection(context, isDesktop),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
              _buildStickyHeader(context, isDesktop),
              const AdminEditToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context, bool isDesktop) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 900 && width < 1200;
    final bool isMobile = width < 700;

    Widget buildLogo() {
      return Image.asset(
        'assets/images/Logo.png', // Direct asset reference (not theme-aware)
        height: isDesktop
            ? 90 // Desktop: 90px (increased from 80px, then 72px)
            : isTablet
                ? 70 // Tablet: 70px (increased from 68px, then 64px)
                : 60, // Mobile: 60px (increased from 54px, then 48px)
        fit: BoxFit.contain,
      );
    }

    PopupMenuButton<String> buildMenuButton() {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onSelected: (value) {
          switch (value) {
            case 'platform':
              _scrollTo(_platformKey);
              break;
            case 'workflow':
              _handleWorkflowTap();
              break;
            case 'ai':
              _handleKazAiTap();
              break;
            case 'cta':
              _scrollTo(_ctaKey);
              break;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'platform', child: Text('Platform')),
          PopupMenuItem(value: 'workflow', child: Text('Workflow')),
          PopupMenuItem(value: 'ai', child: Text('KAZ AI')),
          PopupMenuItem(value: 'cta', child: Text('Pricing')),
        ],
      );
    }

    Widget buildSignInButton({bool fullWidth = false}) {
      final button = TextButton(
        onPressed: () {
          if (_isDebugMode) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            );
          } else {
            _showComingSoonDialog();
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: fullWidth ? 16 : 20, vertical: 12),
          minimumSize: const Size(0, 44),
        ),
        child: const Text('Sign In',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      );

      return fullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button;
    }

    Widget buildStartProjectButton({bool fullWidth = false}) {
      final button = ElevatedButton(
        onPressed: _handleStartProject,
        style: ElevatedButton.styleFrom(
          backgroundColor: LightModeColors.accent,
          foregroundColor: const Color(0xFF151515),
          padding: EdgeInsets.symmetric(
              horizontal: fullWidth ? 16 : 26, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          minimumSize: const Size(0, 48),
        ),
        child: const Text('Start Your Project',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      );

      return fullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button;
    }

    Widget buildTabletOrDesktopContent() {
      return Row(
        children: [
          buildLogo(),
          if (isDesktop) ...[
            const SizedBox(width: 32),
            _navButton('Platform', () => _scrollTo(_platformKey)),
            _navButton('Workflow', _handleWorkflowTap),
            _navButton('KAZ AI', _handleKazAiTap),
            _navButton('Pricing', () => _scrollTo(_ctaKey)),
          ],
          const Spacer(),
          if (!isDesktop) ...[
            buildMenuButton(),
            const SizedBox(width: 12),
          ],
          buildSignInButton(),
          const SizedBox(width: 12),
          Flexible(child: buildStartProjectButton()),
        ],
      );
    }

    Widget buildMobileContent() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: buildLogo()),
              const SizedBox(width: 12),
              buildMenuButton(),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildSignInButton(fullWidth: true),
              const SizedBox(height: 10),
              buildStartProjectButton(fullWidth: true),
            ],
          ),
        ],
      );
    }

    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 64
                  : isMobile
                      ? 16
                      : 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop
                        ? 32
                        : isMobile
                            ? 16
                            : 20,
                    vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withValues(alpha: 0.82),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: isMobile
                    ? buildMobileContent()
                    : buildTabletOrDesktopContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop) {
    const List<List<String>> highlights = [
      ['Project', 'Agile Project'],
      ['Program', 'Waterfall Project'],
      ['Portfolio', 'Hybrid Project'],
    ];

    final metrics = [
      const _MetricData(
        value: 30,
        suffix: '%',
        label: 'Savings on budget',
        caption: '',
      ),
      const _MetricData(
        value: 88,
        suffix: '%',
        label: 'Improvement to ROI',
        caption: '',
      ),
      const _MetricData(
        value: 40,
        suffix: '% to 60%',
        label: 'Time-to-market reduction',
        caption: '',
      ),
      const _MetricData(
        value: 96,
        suffix: '%',
        label: 'Customer satisfaction',
        caption: '',
      ),
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 96 : 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141414), Color(0xFF050505)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 60,
                offset: const Offset(0, 36),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        LightModeColors.accent.withValues(alpha: 0.32),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF101010), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isDesktop ? 64 : 36),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: _buildHeroContent(
                                  context, highlights, metrics, true)),
                          const SizedBox(width: 54),
                          Expanded(child: _buildHeroVisual(context)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeroContent(
                              context, highlights, metrics, false),
                          const SizedBox(height: 40),
                          _buildHeroVisual(context),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(
    BuildContext context,
    List<List<String>> highlights,
    List<_MetricData> metrics,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  size: 18,
                  color: LightModeColors.accent.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Text(
                'Project management powered by KAZ AI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFF3C0), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Deliver projects to propel your business\' competitive advantage.',
            key: const Key('hero_tagline_text'),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 50.0 : 36.0,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Set project up for success by capturing requirements, deciding on design, and meticulously planning all aspects.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 20 : 18,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: highlights
              .map(
                (pair) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text(pair[0]),
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      selected: false,
                      selectedColor: LightModeColors.accent,
                      backgroundColor: LightModeColors.accent,
                      side: BorderSide(
                          color: LightModeColors.accent.withValues(alpha: 0.4),
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    const SizedBox(height: 8),
                    ChoiceChip(
                      label: Text(pair[1]),
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      selected: false,
                      selectedColor: Colors.white.withValues(alpha: 0.85),
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3), width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _handleStartProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: const Color(0xFF151515),
                padding:
                    const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Start Your Project',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            OutlinedButton(
              onPressed: () => _scrollTo(_platformKey),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.92),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.26), width: 1.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Explore platform',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_outward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Opacity(
          opacity: 0.65,
          child: Wrap(
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            spacing: 20,
            runSpacing: 12,
            children: const [
              Text('Integrate with ERPs',
                  style: TextStyle(color: Colors.white)),
              Text('Integrate with CRMs',
                  style: TextStyle(color: Colors.white)),
              Text('Integrate with Design Tools',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Divider(color: Colors.white.withValues(alpha: 0.12)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: metrics.map((metric) => _buildMetricCard(metric)).toList(),
        ),
      ],
    );
  }

  Widget _buildHeroVisual(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isWide = screenSize.width >= 1200;

    final List<_DeliveryIllustrationData> illustrationData = const [
      _DeliveryIllustrationData(
        title: 'Projects',
        description:
            'Focused initiatives delivering defined outcomes with clear scope and velocity.',
        highlights: ['Single charter', 'Rapid execution'],
        colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
        icon: Icons.task_alt_rounded,
        assetPath: 'assets/images/project-management.png',
      ),
      _DeliveryIllustrationData(
        title: 'Programs',
        description:
            'Coordinated projects aligned to shared benefits, managed through orchestration.',
        highlights: ['Cross-team flow', 'Benefit mapping'],
        colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
        icon: Icons.device_hub_rounded,
        assetPath: 'assets/images/monitoring.png',
      ),
      _DeliveryIllustrationData(
        title: 'Portfolios',
        description:
            'Strategic themes balancing investments, resources, and transformation readiness.',
        highlights: ['Strategic guardrails', 'Capacity balance'],
        colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
        icon: Icons.auto_graph_rounded,
        assetPath: 'assets/images/professional-portfolio.png',
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(
            minHeight: isWide ? 700 : 900,
            maxWidth: isWide ? double.infinity : 1400,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF171717), Color(0xFF060606)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 28),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -80,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          LightModeColors.accent.withValues(alpha: 0.45),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: -100,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFF2563EB), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF131313), Color(0xFF070707)],
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool horizontalLayout =
                              constraints.maxWidth >= 720;
                          final bool twoColumnCards =
                              constraints.maxWidth >= 560;
                          final bool threeColumnCards =
                              constraints.maxWidth >= 980;
                          const double cardSpacing = 18;

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LayoutBuilder(
                                  builder: (context, buttonConstraints) {
                                    final double buttonWidth =
                                        buttonConstraints.maxWidth;
                                    final bool stackButtons = buttonWidth < 900;

                                    if (stackButtons) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: buttonWidth),
                                            child: _HeroActionButton(
                                              label: 'Schedule Consultations',
                                              icon:
                                                  Icons.calendar_month_rounded,
                                              onTap: () => _launchExternalLink(
                                                  'https://calendly.com/chimmie-nduproject'),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: buttonWidth),
                                            child: _HeroActionButton(
                                              label:
                                                  'Personnel Training & PM Process Request',
                                              icon: Icons.people_alt_rounded,
                                              onTap: () => _launchExternalLink(
                                                  'https://forms.gle/18n6hihK7DtAaKg28'),
                                              isSecondary: true,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _HeroActionButton(
                                          label: 'Schedule Consultations',
                                          icon: Icons.calendar_month_rounded,
                                          onTap: () => _launchExternalLink(
                                              'https://calendly.com/chimmie-nduproject'),
                                        ),
                                        _HeroActionButton(
                                          label:
                                              'Personnel Training & PM Process Request',
                                          icon: Icons.people_alt_rounded,
                                          onTap: () => _launchExternalLink(
                                              'https://forms.gle/18n6hihK7DtAaKg28'),
                                          isSecondary: true,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                LayoutBuilder(
                                  builder: (context, wrapConstraints) {
                                    final double availableWidth =
                                        wrapConstraints.maxWidth;
                                    final double availableHeight =
                                        MediaQuery.of(context).size.height -
                                            400;

                                    // Adjust responsive breakpoints for smaller desktop screens
                                    final bool shouldUseThreeColumns =
                                        availableWidth >= 980;
                                    final bool shouldUseTwoColumns =
                                        availableWidth >= 560 &&
                                            availableWidth < 980;
                                    final bool shouldUseOneColumn =
                                        availableWidth < 560;

                                    final EdgeInsets cardPadding =
                                        EdgeInsets.symmetric(
                                      horizontal: shouldUseThreeColumns ||
                                              shouldUseTwoColumns
                                          ? 18
                                          : 16,
                                      vertical: 16,
                                    );

                                    double cardWidth;
                                    if (shouldUseThreeColumns) {
                                      cardWidth =
                                          (availableWidth - (cardSpacing * 2)) /
                                              3;
                                    } else if (shouldUseTwoColumns) {
                                      cardWidth =
                                          (availableWidth - cardSpacing) / 2;
                                    } else {
                                      cardWidth = availableWidth;
                                    }

                                    final cardsWidget = Wrap(
                                      spacing: cardSpacing,
                                      runSpacing: cardSpacing,
                                      alignment: horizontalLayout
                                          ? WrapAlignment.start
                                          : WrapAlignment.center,
                                      children: illustrationData.map((data) {
                                        return SizedBox(
                                          width: cardWidth,
                                          child: _DeliveryIllustrationCard(
                                            data: data,
                                            padding: cardPadding,
                                          ),
                                        );
                                      }).toList(),
                                    );

                                    // Calculate estimated height needed for cards
                                    final cardHeight =
                                        220.0; // Approximate card height
                                    final rows = shouldUseThreeColumns
                                        ? 1
                                        : (shouldUseTwoColumns ? 2 : 3);
                                    final estimatedHeight =
                                        (cardHeight * rows) +
                                            (cardSpacing * (rows - 1));

                                    // If content would overflow, wrap in scrollable container
                                    if (estimatedHeight > availableHeight) {
                                      return SizedBox(
                                        height: availableHeight.clamp(300, 500),
                                        child: SingleChildScrollView(
                                          child: cardsWidget,
                                        ),
                                      );
                                    }

                                    return cardsWidget;
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveProgramCard() {
    final List<Map<String, dynamic>> segments = [
      {
        'title': 'Project',
        'methodologies': ['Agile', 'Waterfall', 'Hybrid']
      },
      {
        'title': 'Program',
        'methodologies': ['Agile', 'Waterfall', 'Hybrid']
      },
      {
        'title': 'Portfolio',
        'methodologies': ['Agile', 'Waterfall', 'Hybrid']
      },
    ];

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 26,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  LightModeColors.accent.withValues(alpha: 0.95),
                  LightModeColors.accent.withValues(alpha: 0.65),
                ],
              ),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Color(0xFF111827), size: 24),
          ),
          const SizedBox(height: 18),
          Text(
            'Executive Program Command',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'World-class orchestration designed for enterprise delivery teams.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_mosaic_rounded,
                        color: LightModeColors.accent.withValues(alpha: 0.92),
                        size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Delivery view',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: segments
                      .map(
                        (segment) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: LightModeColors.accent
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                      color: LightModeColors.accent
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  segment['title']!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children:
                                    (segment['methodologies'] as List<String>)
                                        .map(
                                          (method) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.white
                                                  .withValues(alpha: 0.08),
                                              border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.12)),
                                            ),
                                            child: Text(
                                              method,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingPortfolioCard({double? width}) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.9),
                      const Color(0xFFD946EF).withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: const Icon(Icons.auto_graph_rounded,
                    color: Color(0xFF111827), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolios',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Strategic guardrails balancing investments, resources, and readiness.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroMetricChip(
                  label: 'Investment mix aligned',
                  icon: Icons.pie_chart_rounded),
              _HeroMetricChip(
                  label: 'Capacity plan synced', icon: Icons.groups_rounded),
            ],
          ),
        ],
      ),
    );

    return width != null ? SizedBox(width: width, child: card) : card;
  }

  Widget _floatingTimelineCard({double? width}) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Critical path',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _timelineRow('Initiation', 'Complete', true),
          const SizedBox(height: 12),
          _timelineRow('Planning', 'In motion', true),
          const SizedBox(height: 12),
          _timelineRow('Execution', 'ETA 14 days', false),
        ],
      ),
    );

    return width != null ? SizedBox(width: width, child: card) : card;
  }

  Widget _timelineRow(String title, String subtitle, bool done) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? LightModeColors.accent.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(_MetricData metric) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final easedValue = Curves.easeOutCubic.transform(_animController.value);
        final animated = metric.value * easedValue;
        final valueText = '${animated.toStringAsFixed(0)}${metric.suffix}';

        return SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valueText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                metric.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              if (metric.caption.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metric.caption,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMomentumStrip(bool isDesktop) {
    final momentumItems = [
      const _MomentumData(
          title: '40+ specialized workspaces',
          description:
              'Including requirements, procurement, contracts, technology, risk, SSHER, and more.'),
      const _MomentumData(
          title: 'KAZ AI assistance throughout the product delivery process',
          description:
              'Surface next best actions and clarify documentation in seconds.'),
      const _MomentumData(
          title: 'Enterprise-grade collaboration',
          description:
              'Stakeholder views, approvals, and governance designed for complex teams.'),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 96 : 24),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 24, vertical: isDesktop ? 26 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141414), Color(0xFF060606)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 36,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final double spacing = 24;
          final int columns;
          if (maxWidth >= 960) {
            columns = 3;
          } else if (maxWidth >= 640) {
            columns = 2;
          } else {
            columns = 1;
          }
          final double itemWidth = columns == 1
              ? maxWidth
              : (maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: momentumItems
                .map(
                  (item) => SizedBox(
                    width: itemWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                LightModeColors.accent.withValues(alpha: 0.9),
                                LightModeColors.accent.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                          child: const Icon(Icons.star_rate_rounded,
                              color: Color(0xFF111827)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.78),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildPlatformSection(BuildContext context, bool wideLayout) {
    final capability = [
      const _CapabilityData(
        icon: Icons.account_tree_rounded,
        title: 'Front-end Planning',
        description:
            'Structure the entire initiation phase with guided workspaces for program basics, stakeholder mapping, and opportunity framing.',
        bulletPoints: [
          'Live workspace for requirements, technology, and procurement decisions',
          'Template-driven reviews to align leadership and delivery teams',
          'Real-time notes roll-up for executive briefings',
        ],
        gradient: [Color(0xFF3B82F6), Color(0xFF6366F1)],
      ),
      const _CapabilityData(
        icon: Icons.health_and_safety_rounded,
        title: 'Risk & SSHER',
        description:
            'Spot issues before they become blockers with unified risk matrices, safety dashboards, and environmental insights.',
        bulletPoints: [
          'SSHER scoring model with mitigation recommendations',
          'Automated alerts across health, environment, and regulatory impact',
          'Scenario planning to balance opportunity vs. risk exposure',
        ],
        gradient: [Color(0xFFF97316), Color(0xFFEF4444)],
      ),
      const _CapabilityData(
        icon: Icons.group_work_rounded,
        title: 'Team Collaboration',
        description:
            'Unify training, responsibilities, and change management to keep every function aligned on delivery.',
        bulletPoints: [
          'Personnel readiness dashboards with gaps surfaced instantly',
          'Engagement for stakeholders & cross-functional teams',
          'AI-powered change requests',
        ],
        gradient: [Color(0xFF10B981), Color(0xFF0EA5E9)],
      ),
      const _CapabilityData(
        icon: Icons.route_rounded,
        title: 'Work Breakdown Structure',
        description:
            'Transform plans into actionable delivery with layered WBS, dependencies, and milestone visualizations.',
        bulletPoints: [
          'Interface management across project scope.',
          'Critical path visualizations with AI anomaly detection',
          'Roadmap exports tailored for leadership, teams, and partners',
        ],
        gradient: [Color(0xFF8B5CF6), Color(0xFFDB2777)],
      ),
      const _CapabilityData(
        icon: Icons.payments_rounded,
        title: 'Finance & Procurement',
        description:
            'Keep budgets tight with contract visibility, procurement controls, and integrated cost analysis.',
        bulletPoints: [
          'Scenario budgets with guardrails for approvals',
          'Procurement workspace that surfaces supplier readiness',
          'Deliverable forecasts tied to spend and variance alerts',
        ],
        gradient: [Color(0xFFF59E0B), Color(0xFFFACC15)],
      ),
      const _CapabilityData(
        icon: Icons.support_agent_rounded,
        title: 'KAZ AI assistance',
        description:
            'Guidance, summaries, and answers in context. KAZ AI keeps every page actionable with conversational intelligence.',
        bulletPoints: [
          'Automatic application of project activities',
          'Suggested next best actions per workspace',
          'Profitability analysis',
        ],
        gradient: [Color(0xFF38BDF8), Color(0xFFFFC107)],
      ),
    ];

    return Container(
      key: _platformKey,
      margin: EdgeInsets.symmetric(horizontal: wideLayout ? 96 : 24),
      padding: EdgeInsets.symmetric(
          horizontal: wideLayout ? 64 : 28, vertical: wideLayout ? 84 : 56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121212), Color(0xFF050505)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 60,
            offset: const Offset(0, 34),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The effective platform for sound project management.',
            key: const Key('agile_section_tagline_text'),
            style: TextStyle(
              fontSize: wideLayout ? 40 : 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Each phase is incorporates project delivery best practices as the blueprint for a successful project',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double spacing = 24;
              final int columns;
              if (maxWidth >= 1040) {
                columns = 3;
              } else if (maxWidth >= 680) {
                columns = 2;
              } else {
                columns = 1;
              }
              final double itemWidth = columns == 1
                  ? maxWidth
                  : (maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: capability
                    .map(
                      (cap) => SizedBox(
                          width: itemWidth, child: _CapabilityCard(data: cap)),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowSection(BuildContext context, bool wideLayout) {
    final steps = [
      const _WorkflowStep(
        step: '01',
        title: 'Initiate & Align',
        description: 'Including cost, schedule, procurement, and contracts',
        spotlight:
            'Requirements, design, technology, quality, cost estimation & cost mobilization, schedule',
      ),
      const _WorkflowStep(
        step: '02',
        title: 'Architect the Plan',
        description:
            'Design technology, infrastructure, procurement, and personnel strategies with connected workspaces.',
        spotlight: 'Technology • Procurement • Contracts • Infrastructure',
      ),
      const _WorkflowStep(
        step: '03',
        title: 'Execute & Control',
        description:
            'Work the plan while ensuring requirements are met, costs are tracked, and the project remains on schedule.',
        spotlight:
            'Team training • Change management • Iteration • Deliverables',
      ),
      const _WorkflowStep(
        step: '04',
        title: 'Operationalize Delivery',
        description:
            'Operationalize delivery surface fast track decision and drive continuous improvement across projects.',
        spotlight: 'Checklist • Analytics • Gap analysis • Reconciliation',
      ),
    ];

    return Container(
      key: _workflowKey,
      margin: EdgeInsets.symmetric(horizontal: wideLayout ? 96 : 24),
      padding: EdgeInsets.symmetric(
          horizontal: wideLayout ? 64 : 28, vertical: wideLayout ? 80 : 56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF121212), Color(0xFF060606)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 48,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orchestrate every phase with applicable core project management framework',
            key: const Key('waterfall_section_tagline_text'),
            style: TextStyle(
              fontSize: wideLayout ? 38 : 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Efficient workflows that incorporate pertinent aspects of projects and programs.',
            style: TextStyle(
              fontSize: 17,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double spacing = 28;
              final int columns;
              if (maxWidth >= 1024) {
                columns = 4;
              } else if (maxWidth >= 720) {
                columns = 2;
              } else {
                columns = 1;
              }
              final double itemWidth = columns == 1
                  ? maxWidth
                  : (maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: steps
                    .map(
                      (step) => SizedBox(
                          width: itemWidth, child: _WorkflowCard(step: step)),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKazAISection(BuildContext context, bool isDesktop) {
    final conversations = const [
      _ConversationBubble(
          role: 'You',
          message:
              'KAZ AI what are the potential risks with launching a virtual fitting room?'),
      _ConversationBubble(
          role: 'KAZ AI',
          message:
              'Here are the critical risk themes to monitor: data privacy compliance, store associate adoption, and integration stability with your ecommerce stack.'),
      _ConversationBubble(
          role: 'KAZ AI',
          message:
              'Mitigation playbook drafted—schedule security validation, align change enablement, and add rollout checkpoints for the pilot markets.'),
    ];

    return Container(
      key: _aiKey,
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 96 : 24),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 28, vertical: isDesktop ? 72 : 52),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121212), Color(0xFF050505)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 54,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildKazAIContent()),
                const SizedBox(width: 48),
                Expanded(child: _buildKazAIChat(conversations)),
              ],
            )
          : Column(
              children: [
                _buildKazAIContent(),
                const SizedBox(height: 36),
                _buildKazAIChat(conversations),
              ],
            ),
    );
  }

  Widget _buildKazAIContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('KAZ AI copilot',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'AI assistance throughout the project delivery process',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'KAZ AI is wired into each workspace, turning your planning artifacts into conversational intelligence.',
          style: TextStyle(
            fontSize: 17,
            color: Colors.white.withValues(alpha: 0.78),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _KazAiBullet(
                title: 'Context-aware answers',
                subtitle:
                    'Ask about contracts, requirements, or training and get answers citing the exact workspace.'),
            SizedBox(height: 16),
            _KazAiBullet(
                title: 'Action acceleration',
                subtitle:
                    'KAZ AI generates briefs, next-step checklists, and executive-ready updates instantly.'),
            SizedBox(height: 16),
            _KazAiBullet(
                title: 'Guided decisioning',
                subtitle:
                    'KAZ AI helps with details that make the project delivery process more robust.'),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_rounded,
                  color: LightModeColors.accent.withValues(alpha: 0.95)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'KAZ AI follows your governance rules—keeping approvals tracked, content scoped, and data secure.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKazAIChat(List<_ConversationBubble> conversations) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C0C0C), Color(0xFF191919)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                colors: [
                  LightModeColors.accent.withValues(alpha: 0.85),
                  LightModeColors.accent.withValues(alpha: 0.55)
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Color(0xFF1F2937)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('KAZ AI Live Assistant',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF1F2937))),
                    Text('Always-on copilots across your program',
                        style:
                            TextStyle(color: Color(0xFF1F2937), fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: const Text('Online',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: conversations
                  .map(
                    (bubble) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Align(
                        alignment: bubble.role == 'You'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: bubble.role == 'You'
                                ? Colors.white.withValues(alpha: 0.14)
                                : Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bubble.role,
                                style: TextStyle(
                                  color: bubble.role == 'You'
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : LightModeColors.accent
                                          .withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                bubble.message,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
              color: Colors.black.withValues(alpha: 0.2),
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            color:
                                LightModeColors.accent.withValues(alpha: 0.9),
                            size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ask KAZ AI how to accelerate this week\'s milestone...',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        LightModeColors.accent.withValues(alpha: 0.95),
                        LightModeColors.accent.withValues(alpha: 0.7)
                      ],
                    ),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Color(0xFF1F2937), size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(BuildContext context, bool wideLayout) {
    final testimonials = [
      const _TestimonialData(
        quote:
            '"KAZ AI keeps us ahead of risk. We moved from reactive updates to proactive steering meetings—every stakeholder sees the same truth."',
        name: 'Director of PMO',
        company: 'Global Infrastructure Program',
      ),
      const _TestimonialData(
        quote:
            '“Front-end planning used to take six weeks. Our last program cleared approvals in under two, with every decision trail documented.”',
        name: 'Program Lead',
        company: 'Fortune 200 Manufacturing',
      ),
      const _TestimonialData(
        quote:
            '“The WBS workspace is unreal—dependencies, change requests, and readiness indicators update live. Execs finally trust the dashboards.”',
        name: 'Head of Delivery',
        company: 'Enterprise Services',
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: wideLayout ? 96 : 24),
      padding: EdgeInsets.symmetric(
          horizontal: wideLayout ? 64 : 28, vertical: wideLayout ? 72 : 48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121212), Color(0xFF070707)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teams running the future trust NDU Project',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final int columns;
              if (maxWidth >= 940) {
                columns = 3;
              } else if (maxWidth >= 620) {
                columns = 2;
              } else {
                columns = 1;
              }
              final double spacing = 24;
              final double itemWidth = columns == 1
                  ? maxWidth
                  : (maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: testimonials
                    .map((testimonial) => SizedBox(
                        width: itemWidth,
                        child: _TestimonialCard(data: testimonial)))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context, bool isDesktop) {
    return Container(
      key: _ctaKey,
      margin: EdgeInsets.fromLTRB(
          isDesktop ? 96 : 24, 0, isDesktop ? 96 : 24, isDesktop ? 80 : 56),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 72 : 32, vertical: isDesktop ? 76 : 56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111111), Color(0xFF040404)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 44,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Deliver your project, programs and portfolio from start to launch within our platform.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 40 : 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Start a free trial and access every workspace, KAZ AI, and executive-ready report.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17, color: Colors.white.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _handleStartProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: const Color(0xFF151515),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 42, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Start Your Project',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              OutlinedButton(
                onPressed: () {
                  if (_isDebugMode) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  } else {
                    _showComingSoonDialog();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Partner with us',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, bool isDesktop) {
    return _FAQSectionWidget(isDesktop: isDesktop);
  }

  Widget _buildTermsContent(bool isDesktop) {
    final terms = [
      _TermsSection(
        title: '1. Acceptance of Terms',
        content:
            'By accessing and using NDU Project, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
      ),
      _TermsSection(
        title: '2. Use License',
        content:
            'Permission is granted to temporarily use NDU Project for personal or commercial project management purposes. This is the grant of a license, not a transfer of title, and under this license you may not: modify or copy the materials; use the materials for any commercial purpose or for any public display; attempt to reverse engineer any software contained in NDU Project; remove any copyright or other proprietary notations from the materials.',
      ),
      _TermsSection(
        title: '3. User Accounts',
        content:
            'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account or password. You must notify us immediately of any unauthorized use of your account.',
      ),
      _TermsSection(
        title: '4. Service Availability',
        content:
            'We strive to ensure that NDU Project is available 24/7, but we do not guarantee uninterrupted access. We reserve the right to modify, suspend, or discontinue any part of the service at any time with or without notice.',
      ),
      _TermsSection(
        title: '5. Data and Privacy',
        content:
            'Your use of NDU Project is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices regarding the collection and use of your data.',
      ),
      _TermsSection(
        title: '6. Intellectual Property',
        content:
            'All content, features, and functionality of NDU Project, including but not limited to text, graphics, logos, and software, are the exclusive property of NDU Project and are protected by international copyright, trademark, and other intellectual property laws.',
      ),
      _TermsSection(
        title: '7. Limitation of Liability',
        content:
            'In no event shall NDU Project or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use NDU Project, even if NDU Project or an authorized representative has been notified orally or in writing of the possibility of such damage.',
      ),
      _TermsSection(
        title: '8. Modifications',
        content:
            'NDU Project may revise these terms of service at any time without notice. By using this service you are agreeing to be bound by the then current version of these terms of service.',
      ),
      _TermsSection(
        title: '9. Contact Information',
        content:
            'If you have any questions about these Terms and Conditions, please contact us at contact@nduproject.com or Phone (US): +1 (832) 228-3510.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: terms.map((term) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                term.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                term.content,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.7,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyContent(bool isDesktop) {
    final privacySections = [
      _PrivacySection(
        title: '1. Information We Collect',
        content:
            'We collect information that you provide directly to us, including: account registration information (name, email, company), project data and content you create or upload, communication data when you contact us, and usage data about how you interact with our platform.',
      ),
      _PrivacySection(
        title: '2. How We Use Your Information',
        content:
            'We use the information we collect to: provide, maintain, and improve our services, process transactions and send related information, send technical notices and support messages, respond to your comments and questions, monitor and analyze trends and usage, and detect, prevent, and address technical issues.',
      ),
      _PrivacySection(
        title: '3. Information Sharing and Disclosure',
        content:
            'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances: with your consent, to comply with legal obligations, to protect our rights and safety, with service providers who assist us in operating our platform (under strict confidentiality agreements), and in connection with a business transfer or merger.',
      ),
      _PrivacySection(
        title: '4. Data Security',
        content:
            'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes encryption, secure authentication, regular security audits, and access controls. However, no method of transmission over the Internet is 100% secure.',
      ),
      _PrivacySection(
        title: '5. Data Retention',
        content:
            'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. When you delete your account, we will delete or anonymize your personal information, subject to certain exceptions.',
      ),
      _PrivacySection(
        title: '6. Your Rights and Choices',
        content:
            'You have the right to: access and receive a copy of your personal data, rectify inaccurate or incomplete data, request deletion of your personal data, object to processing of your personal data, request restriction of processing, and data portability. You can exercise these rights by contacting us at contact@nduproject.com.',
      ),
      _PrivacySection(
        title: '7. Cookies and Tracking Technologies',
        content:
            'We use cookies and similar tracking technologies to track activity on our platform and hold certain information. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent. However, if you do not accept cookies, you may not be able to use some portions of our service.',
      ),
      _PrivacySection(
        title: '8. Third-Party Services',
        content:
            'Our platform may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read the privacy policies of any third-party services you access.',
      ),
      _PrivacySection(
        title: '9. Children\'s Privacy',
        content:
            'NDU Project is not intended for individuals under the age of 18. We do not knowingly collect personal information from children. If you become aware that a child has provided us with personal information, please contact us immediately.',
      ),
      _PrivacySection(
        title: '10. Changes to This Privacy Policy',
        content:
            'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. You are advised to review this Privacy Policy periodically for any changes.',
      ),
      _PrivacySection(
        title: '11. Contact Us',
        content:
            'If you have any questions about this Privacy Policy, please contact us at: Email: contact@nduproject.com, Phone (US): +1 (832) 228-3510.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: privacySections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                section.content,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.7,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTermsAndConditionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          decoration: BoxDecoration(
            color: const Color(0xFF040404),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terms and Conditions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last updated: ${DateTime.now().year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildTermsContent(true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          decoration: BoxDecoration(
            color: const Color(0xFF040404),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last updated: ${DateTime.now().year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NDU Project ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPrivacyContent(true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 1100;
    final bool isMobile = size.width < 700;

    final columns = [
      _FooterColumnData(
        title: 'Platform',
        links: [
          _FooterLinkData(
              label: 'Front-End Planning',
              onTap: () => _scrollTo(_platformKey)),
          _FooterLinkData(
              label: 'Risk & SSHER Intelligence',
              onTap: () => _scrollTo(_workflowKey)),
          _FooterLinkData(
              label: 'Team Collaboration',
              onTap: () => _scrollTo(_workflowKey)),
          _FooterLinkData(
              label: 'KAZ AI Copilot', onTap: () => _scrollTo(_aiKey)),
        ],
      ),
      _FooterColumnData(
        title: 'Solutions',
        links: const [
          _FooterLinkData(label: 'Agile'),
          _FooterLinkData(label: 'Waterfall'),
          _FooterLinkData(label: 'Hybrid'),
        ],
      ),
      _FooterColumnData(
        title: 'Resources',
        links: [
          _FooterLinkData(
              label: 'KAZ AI Playbook.', onTap: () => _scrollTo(_aiKey)),
          const _FooterLinkData(label: 'Security'),
          const _FooterLinkData(label: 'Governance'),
          const _FooterLinkData(label: 'Customer Service'),
          const _FooterLinkData(label: 'Templates'),
          const _FooterLinkData(label: 'Solutions'),
        ],
      ),
      _FooterColumnData(
        title: 'Company',
        links: const [
          _FooterLinkData(label: 'About NDU Project'),
          _FooterLinkData(label: 'Careers'),
          _FooterLinkData(label: 'Press'),
          _FooterLinkData(label: 'Contact'),
        ],
      ),
    ];

    final columnWidget = LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double resolvedWidth = maxWidth >= 540
            ? 240.0
            : (maxWidth <= 320 ? maxWidth : maxWidth / 2);
        return Wrap(
          spacing: 28,
          runSpacing: 28,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: columns
              .map((data) => SizedBox(
                  width: resolvedWidth, child: _FooterColumn(data: data)))
              .toList(),
        );
      },
    );

    final leftBlock = Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Ndu Project is a project delivery platform that enables organizations to save money on projects via robust planning, integrated design, and flawless execution.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 15,
            height: 1.6,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, box) {
            final bool stack = box.maxWidth < 560;
            final content = Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: stack
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    LightModeColors.accent
                                        .withValues(alpha: 0.9),
                                    LightModeColors.accent
                                        .withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.headset_mic_rounded,
                                  color: Color(0xFF111827), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Consult with an expert',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expert guidance to optimize your project outcomes.',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateAccountScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF111827),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text('Book a session',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                LightModeColors.accent.withValues(alpha: 0.9),
                                LightModeColors.accent.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                          child: const Icon(Icons.headset_mic_rounded,
                              color: Color(0xFF111827), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consult with an expert',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expert guidance to optimize your project outcomes.',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateAccountScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF111827),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Book a session',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ],
                    ),
            );
            return content;
          },
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide
            ? 96
            : isMobile
                ? 20
                : 28,
        vertical: isWide
            ? 80
            : isMobile
                ? 42
                : 56,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF040404), Color(0xFF080808), Color(0xFF040404)],
        ),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftBlock),
                const SizedBox(width: 72),
                Expanded(child: columnWidget),
              ],
            )
          else ...[
            leftBlock,
            const SizedBox(height: 36),
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: columnWidget,
              ),
            ),
          ],
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Column(
              crossAxisAlignment: isMobile
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  alignment:
                      isMobile ? WrapAlignment.center : WrapAlignment.start,
                  children: const [
                    _FooterPill(text: 'contact@nduproject.com'),
                    _FooterPill(text: 'Phone (US): +1 (832) 228-3510'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '© 2025 NDU Project. Engineered for leaders building the next wave of critical programs.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showTermsAndConditionsDialog(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showPrivacyPolicyDialog(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQSectionWidget extends StatefulWidget {
  const _FAQSectionWidget({required this.isDesktop});

  final bool isDesktop;

  @override
  State<_FAQSectionWidget> createState() => _FAQSectionWidgetState();
}

class _FAQSectionWidgetState extends State<_FAQSectionWidget> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FAQItem(
        question: 'What is NDU Project?',
        answer:
            'NDU Project is a comprehensive project delivery platform that enables organizations to save money on projects through robust planning, integrated design, and flawless execution. It combines front-end planning, risk intelligence, team collaboration, and AI-powered copilot capabilities.',
      ),
      _FAQItem(
        question: 'How does KAZ AI Copilot work?',
        answer:
            'KAZ AI Copilot is an intelligent assistant that helps project teams with real-time insights, risk identification, and decision support. It analyzes project data, identifies potential issues, and provides actionable recommendations to keep projects on track.',
      ),
      _FAQItem(
        question: 'What project methodologies are supported?',
        answer:
            'NDU Project supports multiple project methodologies including Agile, Waterfall, and Hybrid approaches. The platform is flexible and can be adapted to your organization\'s preferred project management framework.',
      ),
      _FAQItem(
        question: 'Is my data secure?',
        answer:
            'Yes, security is a top priority. We implement industry-standard security measures including encryption, secure authentication, and regular security audits. Your project data is protected and only accessible to authorized team members.',
      ),
      _FAQItem(
        question: 'Can I integrate with existing tools?',
        answer:
            'NDU Project is designed to integrate with common project management and collaboration tools. Contact our team to discuss specific integration requirements for your organization.',
      ),
      _FAQItem(
        question: 'What kind of support is available?',
        answer:
            'We offer comprehensive support including expert consultation, customer service, and access to templates and resources. You can book a consultation session with our experts to optimize your project outcomes.',
      ),
    ];

    return Container(
      key: const ValueKey('faq_section'),
      padding: EdgeInsets.symmetric(
          horizontal: widget.isDesktop ? 96 : 28,
          vertical: widget.isDesktop ? 80 : 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: widget.isDesktop ? 48 : 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Find answers to common questions about NDU Project',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 48),
          ...faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            final isExpanded = expandedIndex == index;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  title: Text(
                    faq.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  trailing: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      expandedIndex = expanded ? index : null;
                    });
                  },
                  children: [
                    Text(
                      faq.answer,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DeliveryIllustrationData {
  const _DeliveryIllustrationData({
    required this.title,
    required this.description,
    required this.highlights,
    required this.colors,
    required this.icon,
    this.assetPath,
  });

  final String title;
  final String description;
  final List<String> highlights;
  final List<Color> colors;
  final IconData icon;
  final String? assetPath;
}

class _DeliveryIllustrationCard extends StatelessWidget {
  const _DeliveryIllustrationCard({required this.data, required this.padding});

  final _DeliveryIllustrationData data;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.colors.first.withValues(alpha: 0.32),
            data.colors.last.withValues(alpha: 0.16),
            data.colors.first.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
            color: data.colors.first.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: data.colors.last.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    data.colors.first.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.colors.first.withValues(alpha: 0.9),
                      data.colors.last.withValues(alpha: 0.7),
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: data.colors.last.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: data.assetPath != null
                    ? ClipOval(
                        child: Image.asset(
                          data.assetPath!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(data.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 18),
              Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                data.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.highlights
                    .map(
                      (highlight) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: data.colors.first.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          highlight,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSecondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(18);
    final BoxDecoration decoration = isSecondary
        ? BoxDecoration(
            borderRadius: radius,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 14),
              ),
            ],
          )
        : BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [
                LightModeColors.accent.withValues(alpha: 0.95),
                LightModeColors.accent.withValues(alpha: 0.75),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: LightModeColors.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 18),
              ),
            ],
          );

    final Color textColor = isSecondary
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFF14213D);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: decoration,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On very small screens, wrap text and stack elements
              final bool shouldWrap = constraints.maxWidth < 300;

              if (shouldWrap) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: textColor),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_outward_rounded,
                      size: 18, color: textColor.withValues(alpha: 0.9)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: LightModeColors.accent.withValues(alpha: 0.9), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _FooterColumnData {
  const _FooterColumnData({required this.title, required this.links});

  final String title;
  final List<_FooterLinkData> links;
}

class _FooterLinkData {
  const _FooterLinkData({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.data});

  final _FooterColumnData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        ...data.links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: link.onTap ?? () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                foregroundColor: Colors.white.withValues(alpha: 0.68),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              child: Text(link.label),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterPill extends StatelessWidget {
  const _FooterPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child:
              Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
        ),
      ),
    );
  }
}

class _TrustedByBadge extends StatelessWidget {
  const _TrustedByBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.value,
    required this.label,
    required this.caption,
    this.suffix = '',
    this.decimals = 0,
  });

  final double value;
  final String label;
  final String caption;
  final String suffix;
  final int decimals;
}

class _MomentumData {
  const _MomentumData({required this.title, required this.description});

  final String title;
  final String description;
}

class _CapabilityData {
  const _CapabilityData({
    required this.icon,
    required this.title,
    required this.description,
    required this.bulletPoints,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> bulletPoints;
  final List<Color> gradient;
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.data});

  final _CapabilityData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.gradient.first.withValues(alpha: 0.22),
            const Color(0xFF090909)
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  data.gradient.first.withValues(alpha: 0.9),
                  data.gradient.last.withValues(alpha: 0.8)
                ],
              ),
            ),
            child: Icon(data.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 24),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          ...data.bulletPoints.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.gradient.first.withValues(alpha: 0.9),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 14,
                          height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStep {
  const _WorkflowStep({
    required this.step,
    required this.title,
    required this.description,
    required this.spotlight,
  });

  final String step;
  final String title;
  final String description;
  final String spotlight;
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.step});

  final _WorkflowStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              step.step,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            step.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.6,
                fontSize: 14),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.explore_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.spotlight,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationBubble {
  const _ConversationBubble({required this.role, required this.message});

  final String role;
  final String message;
}

class _KazAiBullet extends StatelessWidget {
  const _KazAiBullet({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.6,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestimonialData {
  const _TestimonialData(
      {required this.quote, required this.name, required this.company});

  final String quote;
  final String name;
  final String company;
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.data});

  final _TestimonialData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 14),
          Text(
            data.quote,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.6,
                fontSize: 15),
          ),
          const SizedBox(height: 18),
          Text(
            data.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          Text(
            data.company,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  const _FAQItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _TermsSection {
  const _TermsSection({required this.title, required this.content});

  final String title;
  final String content;
}

class _PrivacySection {
  const _PrivacySection({required this.title, required this.content});

  final String title;
  final String content;
}
