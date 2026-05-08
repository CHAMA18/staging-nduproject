import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/screens/pricing_screen.dart';
import 'package:ndu_project/screens/sign_in_screen.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:url_launcher/url_launcher.dart';

// ──────────────────────────── Color Tokens ────────────────────────────
class _LpColors {
  static const bg = Color(0xFF040404);
  static const surface = Color(0xFF0A0A0A);
  static const card = Color(0xFF111111);
  static const border = Color(0xFF1E1E1E);
  static const blue = Color(0xFF2563EB);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF16A34A);
  static const gold = Color(0xFFFFC107); // same as LightModeColors.accent
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
}

// ──────────────────────────── Main Screen ─────────────────────────────
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

  // Section keys for navigation
  final GlobalKey _platformKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _differentiatorsKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  // Debug mode state
  bool _isDebugMode = false;
  int _kazAiTapCount = 0;
  DateTime? _lastKazAiTap;
  int _workflowTapCount = 0;
  DateTime? _lastWorkflowTap;

  // Header opacity for scroll-based effect
  double _headerOpacity = 0.0;

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
    _scrollController.addListener(_onScroll);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (offset / 80).clamp(0.0, 1.0);
    });
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

  // 4 taps on "Platform" nav → toggle debug mode
  void _handleKazAiTap() {
    final now = DateTime.now();
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
      _scrollTo(_platformKey);
    }
  }

  // 5 taps on "How It Works" nav → admin portal
  void _handleWorkflowTap() {
    final now = DateTime.now();
    if (_lastWorkflowTap == null ||
        now.difference(_lastWorkflowTap!) > const Duration(seconds: 2)) {
      _workflowTapCount = 1;
    } else {
      _workflowTapCount++;
    }
    _lastWorkflowTap = now;

    if (_workflowTapCount >= 5) {
      _workflowTapCount = 0;
      context.go('/${AppRoutes.adminPortal}');
      return;
    }

    _scrollTo(_howItWorksKey);
  }

  void _handleStartProject() {
    if (_isDebugMode) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PricingScreen()),
      );
    } else {
      _launchExternalLink('https://calendar.app.google/aGQDFPpmEK9eDh5W6');
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

  // ────────────────── BUILD ──────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 1200;
    final bool isTablet = size.width >= 900 && size.width < 1200;
    final bool isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: _LpColors.bg,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: _LpColors.bg),
          child: Stack(
            children: [
              // Background gradient orbs
              ..._buildBackgroundOrbs(isDesktop),
              // Main scrollable content
              ScrollConfiguration(
                behavior: const _NoGlowScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      SizedBox(height: isDesktop ? 100 : 80),
                      // 1. Hero Section
                      _buildHeroSection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 2. Social Proof / Credibility Bar
                      _buildSocialProofBar(isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 3. The Problem
                      _buildProblemSection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 4. The Solution (PDOS)
                      _buildSolutionSection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 5. How It Works
                      _buildHowItWorksSection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 6. Differentiators
                      _buildDifferentiatorsSection(
                          context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 7. Benefits / Outcomes
                      _buildBenefitsSection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 8. Target Customers
                      _buildTargetCustomersSection(isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 9. Origin & Credibility
                      _buildOriginSection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 10. Core Insight
                      _buildCoreInsightSection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 96 : 64),
                      // 11. Final CTA
                      _buildFinalCTASection(context, isDesktop, isMobile),
                      SizedBox(height: isDesktop ? 64 : 40),
                      // 12. Footer
                      _buildFooter(context, isDesktop, isMobile),
                    ],
                  ),
                ),
              ),
              // Sticky header
              _buildStickyHeader(context, isDesktop, isMobile),
              // Admin edit toggle (must be preserved)
              const AdminEditToggle(),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────── BACKGROUND ORBS ──────────────────
  List<Widget> _buildBackgroundOrbs(bool isDesktop) {
    return [
      Positioned(
        top: -200,
        right: -160,
        child: Container(
          width: isDesktop ? 500 : 300,
          height: isDesktop ? 500 : 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _LpColors.purple.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: 600,
        left: -200,
        child: Container(
          width: isDesktop ? 600 : 350,
          height: isDesktop ? 600 : 350,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _LpColors.blue.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 400,
        right: -180,
        child: Container(
          width: isDesktop ? 500 : 300,
          height: isDesktop ? 500 : 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _LpColors.green.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -100,
        left: -120,
        child: Container(
          width: isDesktop ? 400 : 250,
          height: isDesktop ? 400 : 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _LpColors.gold.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // ────────────────── STICKY HEADER ──────────────────
  Widget _buildStickyHeader(
      BuildContext context, bool isDesktop, bool isMobile) {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : isMobile ? 16 : 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 28 : 16,
                vertical: isDesktop ? 14 : 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black
                    .withValues(alpha: 0.6 + (_headerOpacity * 0.3)),
                border: Border.all(
                  color: Colors.white
                      .withValues(alpha: 0.06 + (_headerOpacity * 0.06)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3 * _headerOpacity),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: isMobile
                  ? _buildMobileHeader(context)
                  : _buildDesktopHeader(context, isDesktop),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        Image.asset(
          'assets/images/Logo.png',
          height: isDesktop ? 72 : 56,
          fit: BoxFit.contain,
        ),
        if (isDesktop) ...[
          const SizedBox(width: 32),
          _navButton('Platform', _handleKazAiTap),
          _navButton('How It Works', _handleWorkflowTap),
          _navButton(
              'Differentiators', () => _scrollTo(_differentiatorsKey)),
          _navButton('Contact', () => _scrollTo(_contactKey)),
        ],
        const Spacer(),
        if (!isDesktop) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'platform':
                  _handleKazAiTap();
                  break;
                case 'howitworks':
                  _handleWorkflowTap();
                  break;
                case 'differentiators':
                  _scrollTo(_differentiatorsKey);
                  break;
                case 'contact':
                  _scrollTo(_contactKey);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'platform', child: Text('Platform')),
              PopupMenuItem(value: 'howitworks', child: Text('How It Works')),
              PopupMenuItem(
                  value: 'differentiators',
                  child: Text('Differentiators')),
              PopupMenuItem(value: 'contact', child: Text('Contact')),
            ],
          ),
          const SizedBox(width: 8),
        ],
        TextButton(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            minimumSize: const Size(0, 40),
          ),
          child: const Text('Sign In',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _handleStartProject,
          style: ElevatedButton.styleFrom(
            backgroundColor: LightModeColors.accent,
            foregroundColor: const Color(0xFF151515),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            minimumSize: const Size(0, 40),
          ),
          child: const Text('Request a Demo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                'assets/images/Logo.png',
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'platform':
                    _handleKazAiTap();
                    break;
                  case 'howitworks':
                    _handleWorkflowTap();
                    break;
                  case 'differentiators':
                    _scrollTo(_differentiatorsKey);
                    break;
                  case 'contact':
                    _scrollTo(_contactKey);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'platform', child: Text('Platform')),
                PopupMenuItem(value: 'howitworks', child: Text('How It Works')),
                PopupMenuItem(
                    value: 'differentiators',
                    child: Text('Differentiators')),
                PopupMenuItem(value: 'contact', child: Text('Contact')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: const Text('Sign In',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleStartProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: const Color(0xFF151515),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Request a Demo',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _navButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────── 1. HERO SECTION ──────────────────
  Widget _buildHeroSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 900),
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 6, child: _buildHeroContent(isDesktop)),
                  const SizedBox(width: 48),
                  Expanded(flex: 5, child: _buildHeroDiagram()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeroContent(isDesktop),
                  const SizedBox(height: 40),
                  _buildHeroDiagram(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroContent(bool isDesktop) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Pill badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  size: 16, color: _LpColors.gold.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Text(
                'AI-Powered Project Delivery',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Headline with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFF3C0),
              Colors.white,
              Color(0xFFE0E7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          blendMode: BlendMode.srcIn,
          child: Text(
            '42% of Projects Fail to meet original scope.\nFix Project Failure Before It Starts',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 48.0 : 32.0,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Subheadline
        Text(
          'Ndu Project is a Project Delivery Operating System (PDOS)—a SaaS platform that integrates AI, analytics, and human decision making to deliver projects from initiation through completion.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            height: 1.65,
            color: _LpColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        // Value props
        ...[
          ('Define, plan, and execute in one continuous system', _LpColors.blue),
          ('Predict risks, delays, and cost impacts before they happen', _LpColors.purple),
          ('Align teams and decisions in real time', _LpColors.green),
        ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: isDesktop
                    ? MainAxisSize.min
                    : MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _LpColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 32),
        // CTAs
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment:
              isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _launchExternalLink(
                  'https://calendar.app.google/aGQDFPpmEK9eDh5W6'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: const Color(0xFF151515),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Request a Demo',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            OutlinedButton(
              onPressed: () => _scrollTo(_howItWorksKey),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('See How It Works',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_downward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroDiagram() {
    return AspectRatio(
      aspectRatio: 1.1,
      child: CustomPaint(
        painter: _SystemDiagramPainter(),
      ),
    );
  }

  // ────────────────── 2. SOCIAL PROOF BAR ──────────────────
  Widget _buildSocialProofBar(bool isDesktop, bool isMobile) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 700),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32, vertical: 32),
      child: Column(
        children: [
          Text(
            'Built from real-world delivery experience across global enterprises and high-growth organizations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    size: 18, color: _LpColors.blue.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text(
                  'Research & Validation: NSF I-Corps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 3. THE PROBLEM ──────────────────
  Widget _buildProblemSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    final painPoints = [
      _PainPoint(Icons.timer_off_rounded, 'No, or rushed, initiation and planning',
          _LpColors.gold),
      _PainPoint(Icons.widgets_outlined, 'Fragmented tools for different project stages',
          _LpColors.purple),
      _PainPoint(Icons.sync_problem_rounded,
          'Misalignment between teams and decisions', _LpColors.blue),
      _PainPoint(Icons.warning_amber_rounded, 'Reactive risk management', Colors.redAccent),
      _PainPoint(
          Icons.replay_rounded, 'Costly rework and delays', _LpColors.gold),
    ];

    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 900),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: Column(
        children: [
          // Section label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'THE PROBLEM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Headline
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.redAccent, Color(0xFFFFC107)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Projects Don\'t Fail in Execution.\nThey Fail Before Execution Begins',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 40.0 : 28.0,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Most project tools focus on tracking work after it starts. But by then, the most critical decisions have already been made… and often made poorly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              height: 1.65,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 48),
          // Pain points grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: painPoints
                .map((p) => SizedBox(
                      width: isDesktop
                          ? 220
                          : isMobile
                              ? (MediaQuery.of(context).size.width - 72)
                              : 200,
                      child: _PainPointCard(painPoint: p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
          // Closing line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              'The issue isn\'t execution. It\'s the lack of a system governing the full lifecycle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 17 : 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 4. THE SOLUTION (PDOS) ──────────────────
  Widget _buildSolutionSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    final capabilities = [
      _Capability(Icons.route_rounded, 'End-to-end delivery', _LpColors.blue),
      _Capability(Icons.sync_rounded,
          'Continuous lifecycle integration\n(initiation → planning → execution → launch)', _LpColors.purple),
      _Capability(Icons.psychology_rounded,
          'AI-driven recommendations', _LpColors.purple),
      _Capability(Icons.analytics_rounded,
          'Predictive analytics for risk and cost', _LpColors.blue),
      _Capability(Icons.hub_rounded,
          'Real-time cross-functional alignment', _LpColors.green),
      _Capability(Icons.check_circle_outline_rounded,
          'Readiness-based execution', _LpColors.green),
    ];

    return Container(
      key: _platformKey,
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 900),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: Column(
        children: [
          // Section label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _LpColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _LpColors.blue.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'THE SOLUTION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _LpColors.blue,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Headline
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_LpColors.blue, _LpColors.purple],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              'A New Category:\nProject Delivery Operating System (PDOS)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 40.0 : 28.0,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ndu Project replaces disconnected tools with a unified system that governs how projects are defined, planned, and delivered.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              height: 1.65,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 48),
          // Capabilities grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: capabilities
                .map((c) => SizedBox(
                      width: isDesktop
                          ? 360
                          : isMobile
                              ? (MediaQuery.of(context).size.width - 72)
                              : 280,
                      child: _CapabilityCard(capability: c),
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
          // CTA
          OutlinedButton(
            onPressed: () => _scrollTo(_howItWorksKey),
            style: OutlinedButton.styleFrom(
              foregroundColor: _LpColors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              side: const BorderSide(color: _LpColors.blue, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Explore the Platform',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 5. HOW IT WORKS ──────────────────
  Widget _buildHowItWorksSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    final steps = [
      _HowItWorksStep(
        number: '01',
        title: 'Define',
        description:
            'Structure strong project foundations with disciplined initiation',
        icon: Icons.fact_check_rounded,
        color: _LpColors.blue,
      ),
      _HowItWorksStep(
        number: '02',
        title: 'Align',
        description:
            'Integrate planning across engineering, procurement, and execution',
        icon: Icons.hub_rounded,
        color: _LpColors.purple,
      ),
      _HowItWorksStep(
        number: '03',
        title: 'Deliver',
        description:
            'Execute with readiness gates, AI insights, and real-time alignment',
        icon: Icons.rocket_launch_rounded,
        color: _LpColors.green,
      ),
    ];

    return Container(
      key: _howItWorksKey,
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 900),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: Column(
        children: [
          // Section label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _LpColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _LpColors.green.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'HOW IT WORKS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _LpColors.green,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_LpColors.green, Color(0xFFE0E7FF)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              'How Ndu Project Delivers Results',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 40.0 : 28.0,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 56),
          // Steps
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _HowItWorksCard(step: steps[0])),
                    _buildStepConnector(_LpColors.blue, _LpColors.purple),
                    Expanded(child: _HowItWorksCard(step: steps[1])),
                    _buildStepConnector(_LpColors.purple, _LpColors.green),
                    Expanded(child: _HowItWorksCard(step: steps[2])),
                  ],
                )
              : Column(
                  children: steps
                      .asMap()
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _HowItWorksCard(step: entry.value),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(Color start, Color end) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [start, end]))),
          Icon(Icons.arrow_forward_rounded, size: 16, color: end),
        ],
      ),
    );
  }

  // ────────────────── 6. DIFFERENTIATORS ──────────────────
  Widget _buildDifferentiatorsSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    final comparisons = [
      _Comparison('Focus on tracking', 'Governs full lifecycle'),
      _Comparison('Reactive insights', 'Predictive analytics'),
      _Comparison('Siloed workflows', 'Integrated system'),
      _Comparison('Execution-focused', 'Initiation-first approach'),
    ];

    final keyPoints = [
      _KeyPoint(Icons.layers_rounded, 'Lifecycle-native architecture', _LpColors.blue),
      _KeyPoint(Icons.psychology_rounded, 'AI + human decision framework', _LpColors.purple),
      _KeyPoint(Icons.tune_rounded, 'Constraint-driven execution', _LpColors.gold),
      _KeyPoint(Icons.sync_rounded, 'Real-time system alignment', _LpColors.green),
    ];

    return Container(
      key: _differentiatorsKey,
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 900),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _LpColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _LpColors.gold.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'DIFFERENTIATORS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _LpColors.gold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_LpColors.gold, Colors.white],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Built Differently From Traditional Project Tools',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 40.0 : 28.0,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Comparison cards
          ...comparisons
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ComparisonCard(comparison: c, isDesktop: isDesktop),
                  )),
          const SizedBox(height: 40),
          // Key points
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: keyPoints
                .map((kp) => SizedBox(
                      width: isDesktop
                          ? 260
                          : isMobile
                              ? (MediaQuery.of(context).size.width - 72)
                              : 200,
                      child: _KeyPointCard(keyPoint: kp),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ────────────────── 7. BENEFITS / OUTCOMES ──────────────────
  Widget _buildBenefitsSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    final outcomes = [
      _Outcome(Icons.trending_down_rounded, 'Reduced rework and cost overruns', _LpColors.green),
      _Outcome(Icons.schedule_rounded, 'Improved schedule predictability', _LpColors.blue),
      _Outcome(Icons.bolt_rounded, 'Faster, higher-quality decisions', _LpColors.purple),
      _Outcome(Icons.show_chart_rounded, 'Increased project ROI', _LpColors.gold),
      _Outcome(Icons.repeat_rounded, 'Scalable, repeatable delivery model', _LpColors.green),
    ];

    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 900),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _LpColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _LpColors.green.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'OUTCOMES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _LpColors.green,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_LpColors.green, Color(0xFFE0E7FF)],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              'What You Achieve with PDOS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 40.0 : 28.0,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Outcome cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: outcomes
                .map((o) => SizedBox(
                      width: isDesktop
                          ? 220
                          : isMobile
                              ? (MediaQuery.of(context).size.width - 72)
                              : 200,
                      child: _OutcomeCard(outcome: o),
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
          // Metric callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A1A0A),
                  Color(0xFF0A0A0A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _LpColors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_LpColors.green, Color(0xFF86EFAC)],
                  ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'Up to 30%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'reduction in rework',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 8. TARGET CUSTOMERS ──────────────────
  Widget _buildTargetCustomersSection(bool isDesktop, bool isMobile) {
    final segments = [
      _CustomerSegment(
        Icons.business_rounded,
        'Enterprises managing capital or transformation programs',
        _LpColors.blue,
      ),
      _CustomerSegment(
        Icons.trending_up_rounded,
        'SMBs scaling through initiative execution',
        _LpColors.green,
      ),
      _CustomerSegment(
        Icons.engineering_rounded,
        'Teams delivering infrastructure, digital, or operational initiatives',
        _LpColors.purple,
      ),
      _CustomerSegment(
        Icons.people_alt_rounded,
        'Consultants adding value to clients\' endeavors',
        _LpColors.gold,
      ),
    ];

    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 900),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _LpColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _LpColors.purple.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'WHO IT\'S FOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _LpColors.purple,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_LpColors.purple, Colors.white],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Built for Organizations Delivering\nSimple to Complex Work',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 40.0 : 28.0,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: segments
                .map((s) => SizedBox(
                      width: isDesktop
                          ? 260
                          : isMobile
                              ? (MediaQuery.of(context).size.width - 56)
                              : 200,
                      child: _SegmentCard(segment: s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ────────────────── 9. ORIGIN & CREDIBILITY ──────────────────
  Widget _buildOriginSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    final creds = [
      _CredBullet('13 years at ExxonMobil', Icons.oil_barrel_rounded, _LpColors.blue),
      _CredBullet('4 years at IBM', Icons.computer_rounded, _LpColors.purple),
      _CredBullet('NSF I-Corps research (34+ interviews)', Icons.science_rounded, _LpColors.green),
    ];

    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 700),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: _GlassCard(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 48 : 28),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _LpColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _LpColors.blue.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'ORIGIN & CREDIBILITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _LpColors.blue,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_LpColors.blue, Colors.white],
                ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Built From Experience.\nValidated by Research.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 36.0 : 26.0,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ndu Project is informed by nearly two decades of hands-on project delivery experience across global enterprises and emerging organizations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 17 : 15,
                  height: 1.65,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              ...creds.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(c.icon, size: 20, color: c.color),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            c.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _LpColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────── 10. CORE INSIGHT ──────────────────
  Widget _buildCoreInsightSection(
      BuildContext context, bool isDesktop, bool isMobile) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 700),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: Column(
        children: [
          // Large statement
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.redAccent, _LpColors.gold, Colors.white],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              '"Execution Doesn\'t Fix Bad Starts"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 44.0 : 30.0,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Projects fail upstream in initiation and planning. Execution only exposes those failures later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              height: 1.65,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          // Bold closing line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A1500),
                  Color(0xFF0A0A0A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _LpColors.gold.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 20, color: _LpColors.gold),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Ndu Project ensures projects start right, and stay right.',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: _LpColors.gold,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 11. FINAL CTA ──────────────────
  Widget _buildFinalCTASection(
      BuildContext context, bool isDesktop, bool isMobile) {
    return Container(
      key: _contactKey,
      constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 700),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32),
      child: _GlassCard(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 56 : 32),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_LpColors.gold, Colors.white],
                ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Ready to Transform How You Deliver Projects?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 38.0 : 26.0,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Move beyond tracking tools. Implement a system designed for real project success.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchExternalLink(
                        'https://calendar.app.google/aGQDFPpmEK9eDh5W6'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LightModeColors.accent,
                      foregroundColor: const Color(0xFF151515),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Start your project',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  OutlinedButton(
                    onPressed: () => _launchExternalLink(
                        'https://calendar.app.google/aGQDFPpmEK9eDh5W6'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Contact Us',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────── 12. FOOTER ──────────────────
  Widget _buildFooter(
      BuildContext context, bool isDesktop, bool isMobile) {
    final productLinks = [
      'Platform', 'How It Works', 'Differentiators', 'Outcomes',
    ];
    final useCaseLinks = [
      'Enterprises', 'SMBs', 'Infrastructure', 'Consultants',
    ];
    final aboutLinks = [
      'Our Story', 'Research', 'NSF I-Corps',
    ];
    final contactLinks = [
      'Request a Demo', 'Contact Us',
    ];

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : isMobile ? 20 : 32, vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand column
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/Logo.png',
                          height: 48, fit: BoxFit.contain),
                      const SizedBox(height: 16),
                      const Text(
                        'Ndu Project — The Project Delivery Operating System',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _LpColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Product
                Expanded(child: _FooterColumn(title: 'Product', links: productLinks)),
                // Use Cases
                Expanded(child: _FooterColumn(title: 'Use Cases', links: useCaseLinks)),
                // About
                Expanded(child: _FooterColumn(title: 'About', links: aboutLinks)),
                // Contact
                Expanded(child: _FooterColumn(title: 'Contact', links: contactLinks)),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/Logo.png',
                    height: 40, fit: BoxFit.contain),
                const SizedBox(height: 12),
                const Text(
                  'Ndu Project — The Project Delivery Operating System',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _LpColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 32,
                  runSpacing: 24,
                  children: [
                    _FooterColumn(title: 'Product', links: productLinks),
                    _FooterColumn(title: 'Use Cases', links: useCaseLinks),
                    _FooterColumn(title: 'About', links: aboutLinks),
                    _FooterColumn(title: 'Contact', links: contactLinks),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 40),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 20),
          // Bottom row
          isDesktop
              ? Row(
                  children: [
                    Text(
                      '© ${DateTime.now().year} Ndu Project. All rights reserved.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _LpColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/${AppRoutes.privacyPolicy}'),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 13,
                          color: _LpColors.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () =>
                          context.go('/${AppRoutes.termsConditions}'),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 13,
                          color: _LpColors.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '© ${DateTime.now().year} Ndu Project. All rights reserved.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _LpColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              context.go('/${AppRoutes.privacyPolicy}'),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 13,
                              color: _LpColors.textMuted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () =>
                              context.go('/${AppRoutes.termsConditions}'),
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 13,
                              color: _LpColors.textMuted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ──────────────────────────── HELPER WIDGETS ──────────────────────────

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

// ──────── Glass Card ────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141414), Color(0xFF080808)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: child,
        ),
      ),
    );
  }
}

// ──────── Pain Point ────────
class _PainPoint {
  final IconData icon;
  final String text;
  final Color color;
  const _PainPoint(this.icon, this.text, this.color);
}

class _PainPointCard extends StatelessWidget {
  final _PainPoint painPoint;
  const _PainPointCard({required this.painPoint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LpColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: painPoint.color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: painPoint.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(painPoint.icon, size: 20, color: painPoint.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              painPoint.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _LpColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Capability ────────
class _Capability {
  final IconData icon;
  final String text;
  final Color color;
  const _Capability(this.icon, this.text, this.color);
}

class _CapabilityCard extends StatelessWidget {
  final _Capability capability;
  const _CapabilityCard({required this.capability});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _LpColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: capability.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: capability.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(capability.icon, size: 22, color: capability.color),
          ),
          const SizedBox(height: 14),
          Text(
            capability.text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _LpColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── How It Works Step ────────
class _HowItWorksStep {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _HowItWorksCard extends StatelessWidget {
  final _HowItWorksStep step;
  const _HowItWorksCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _LpColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: step.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon, size: 24, color: step.color),
              ),
              const SizedBox(width: 14),
              Text(
                step.number,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: step.color.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            step.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: step.color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _LpColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Comparison ────────
class _Comparison {
  final String traditional;
  final String nduProject;
  const _Comparison(this.traditional, this.nduProject);
}

class _ComparisonCard extends StatelessWidget {
  final _Comparison comparison;
  final bool isDesktop;
  const _ComparisonCard({required this.comparison, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _LpColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LpColors.border),
      ),
      child: isDesktop
          ? Row(
              children: [
                // Traditional
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.close_rounded,
                          size: 18,
                          color: Colors.redAccent.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          comparison.traditional,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.45),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: _LpColors.gold.withValues(alpha: 0.7)),
                ),
                // Ndu Project
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: _LpColors.green),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          comparison.nduProject,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _LpColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.close_rounded,
                        size: 16,
                        color: Colors.redAccent.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        comparison.traditional,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.4),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.arrow_downward_rounded,
                      size: 16, color: _LpColors.gold.withValues(alpha: 0.7)),
                ),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: _LpColors.green),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        comparison.nduProject,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _LpColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ──────── Key Point ────────
class _KeyPoint {
  final IconData icon;
  final String text;
  final Color color;
  const _KeyPoint(this.icon, this.text, this.color);
}

class _KeyPointCard extends StatelessWidget {
  final _KeyPoint keyPoint;
  const _KeyPointCard({required this.keyPoint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _LpColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: keyPoint.color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(keyPoint.icon, size: 20, color: keyPoint.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              keyPoint.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _LpColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Outcome ────────
class _Outcome {
  final IconData icon;
  final String text;
  final Color color;
  const _Outcome(this.icon, this.text, this.color);
}

class _OutcomeCard extends StatelessWidget {
  final _Outcome outcome;
  const _OutcomeCard({required this.outcome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _LpColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: outcome.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: outcome.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(outcome.icon, size: 22, color: outcome.color),
          ),
          const SizedBox(height: 14),
          Text(
            outcome.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _LpColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Customer Segment ────────
class _CustomerSegment {
  final IconData icon;
  final String text;
  final Color color;
  const _CustomerSegment(this.icon, this.text, this.color);
}

class _SegmentCard extends StatelessWidget {
  final _CustomerSegment segment;
  const _SegmentCard({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _LpColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: segment.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: segment.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(segment.icon, size: 24, color: segment.color),
          ),
          const SizedBox(height: 14),
          Text(
            segment.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _LpColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────── Cred Bullet ────────
class _CredBullet {
  final String text;
  final IconData icon;
  final Color color;
  const _CredBullet(this.text, this.icon, this.color);
}

// ──────── Footer Column ────────
class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;
  const _FooterColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _LpColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                link,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.3,
                ),
              ),
            )),
      ],
    );
  }
}

// ──────────────────── SYSTEM DIAGRAM PAINTER ────────────────────
class _SystemDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final mainRadius = size.shortestSide * 0.32;

    // Background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _LpColors.purple.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: mainRadius * 1.5));
    canvas.drawCircle(center, mainRadius * 1.5, glowPaint);

    // Draw orbital ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, mainRadius, ringPaint);

    // Draw inner ring
    canvas.drawCircle(center, mainRadius * 0.55, ringPaint);

    // Phase nodes
    final phases = [
      _PhaseNode('Initiation', -1.5708, _LpColors.blue), // top
      _PhaseNode('Planning', 0.5236, _LpColors.purple),  // bottom-right
      _PhaseNode('Execution', 2.6180, _LpColors.green),  // bottom-left
    ];

    final nodeRadius = size.shortestSide * 0.085;

    for (int i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final x = center.dx + mainRadius * (i == 0 ? 0 : (i == 1 ? 0.866 : -0.866));
      final y = center.dy + mainRadius * (i == 0 ? -1 : 0.5);
      final nodeCenter = Offset(x, y);

      // Node glow
      final nodeGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            phase.color.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: nodeCenter, radius: nodeRadius * 2));
      canvas.drawCircle(nodeCenter, nodeRadius * 2, nodeGlow);

      // Node circle
      final nodeFill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phase.color.withValues(alpha: 0.25),
            phase.color.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromCircle(center: nodeCenter, radius: nodeRadius));
      canvas.drawCircle(nodeCenter, nodeRadius, nodeFill);

      // Node border
      final nodeBorder = Paint()
        ..color = phase.color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(nodeCenter, nodeRadius, nodeBorder);

      // Node label
      final textPainter = TextPainter(
        text: TextSpan(
          text: phase.label,
          style: TextStyle(
            fontSize: nodeRadius * 0.42,
            fontWeight: FontWeight.w700,
            color: phase.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          nodeCenter.dx - textPainter.width / 2,
          nodeCenter.dy - textPainter.height / 2,
        ),
      );

      // Draw arrows between nodes
      if (i < phases.length) {
        final nextPhase = phases[(i + 1) % phases.length];
        final nx = center.dx + mainRadius * ((i + 1) % 3 == 0 ? 0 : ((i + 1) % 3 == 1 ? 0.866 : -0.866));
        final ny = center.dy + mainRadius * ((i + 1) % 3 == 0 ? -1 : 0.5);
        final nextCenter = Offset(nx, ny);

        // Calculate direction
        final dx = nextCenter.dx - nodeCenter.dx;
        final dy = nextCenter.dy - nodeCenter.dy;
        final dist = (dx * dx + dy * dy);
        final direction = Offset(dx / dist, dy / dist);

        // Start and end points (offset by node radius)
        final start = Offset(
          nodeCenter.dx + direction.dx * nodeRadius * 1.2,
          nodeCenter.dy + direction.dy * nodeRadius * 1.2,
        );
        final end = Offset(
          nextCenter.dx - direction.dx * nodeRadius * 1.2,
          nextCenter.dy - direction.dy * nodeRadius * 1.2,
        );

        // Draw arc between nodes
        final arrowPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              phase.color.withValues(alpha: 0.5),
              nextPhase.color.withValues(alpha: 0.5),
            ],
          ).createShader(Rect.fromPoints(start, end))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final midX = (start.dx + end.dx) / 2;
        final midY = (start.dy + end.dy) / 2;
        // Pull control point slightly outward from center
        final pullDir = Offset(midX - center.dx, midY - center.dy);
        final pullLen = (pullDir.dx * pullDir.dx + pullDir.dy * pullDir.dy);
        final controlPoint = Offset(
          midX + (pullLen > 0 ? pullDir.dx / pullLen * 30 : 0),
          midY + (pullLen > 0 ? pullDir.dy / pullLen * 30 : 0),
        );

        final path = Path();
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);
        canvas.drawPath(path, arrowPaint);

        // Arrowhead
        const arrowSize = 6.0;
        canvas.save();
        canvas.translate(end.dx, end.dy);
        canvas.rotate(atan2(end.dy - controlPoint.dy, end.dx - controlPoint.dx));
        final arrowPath = Path();
        arrowPath.moveTo(0, 0);
        arrowPath.lineTo(-arrowSize, -arrowSize / 2);
        arrowPath.lineTo(-arrowSize, arrowSize / 2);
        arrowPath.close();
        canvas.drawPath(arrowPath, Paint()..color = nextPhase.color.withValues(alpha: 0.6));
        canvas.restore();
      }
    }

    // Center overlay text: AI + Analytics + Human Decision Making
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _LpColors.purple.withValues(alpha: 0.15),
          _LpColors.gold.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: mainRadius * 0.45));
    canvas.drawCircle(center, mainRadius * 0.45, centerPaint);

    final centerLabels = [
      ('AI', _LpColors.purple),
      ('Analytics', _LpColors.blue),
      ('Human Decisions', _LpColors.gold),
    ];

    for (int i = 0; i < centerLabels.length; i++) {
      final label = centerLabels[i];
      final tp = TextPainter(
        text: TextSpan(
          text: label.$1,
          style: TextStyle(
            fontSize: size.shortestSide * 0.032,
            fontWeight: FontWeight.w700,
            color: label.$2,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final yOffset = center.dy - (centerLabels.length * tp.height * 0.7) / 2 + i * tp.height * 0.85;
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, yOffset),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhaseNode {
  final String label;
  final double angle;
  final Color color;
  const _PhaseNode(this.label, this.angle, this.color);
}


