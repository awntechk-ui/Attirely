
import 'package:flutter/material.dart';

class TermsPolicies extends StatelessWidget {
  const TermsPolicies({super.key});

  static const Color burgundy = Color(0xFF8E2945);
  static const Color darkBurgundy = Color(0xFF4C1026);
  static const Color gold = Color(0xFFE9D8B0);
  static const Color cream = Color(0xFFFFFCF8);

  static const List<Map<String, dynamic>> policies = [
    {
      'icon': Icons.info_outline,
      'title': 'About the Platform',
      'content': [
        'Attirely is a fashion rental platform that connects customers '
            'with vendors offering outfits and accessories for rent.',
        'Attirely provides a platform for discovery and interaction. '
            'Rental arrangements, item availability and fulfilment are '
            'subject to the applicable platform process and vendor terms.',
        'Users and vendors must provide accurate information while '
            'using the platform.',
      ],
    },
    {
      'icon': Icons.storefront_outlined,
      'title': 'Vendor Agreement',
      'content': [
        'Vendors must provide genuine, accurate and up-to-date store '
            'and product information.',
        'Vendors are responsible for ensuring that they have the right '
            'to list and rent the products they upload.',
        'Vendors must keep listing information, photographs, prices, '
            'sizes and availability accurate.',
        'Vendors must not upload misleading, unlawful, counterfeit or '
            'unauthorised content.',
        'Attirely may review, restrict or remove listings that violate '
            'platform rules.',
      ],
    },
    {
      'icon': Icons.checkroom_outlined,
      'title': 'Rental Policies',
      'content': [
        'Customers should review outfit details, measurements, rental '
            'price, availability and applicable conditions before '
            'placing a rental request.',
        'A request does not automatically mean that a rental is '
            'confirmed. Confirmation follows the applicable booking '
            'process.',
        'Vendors should ensure that the listed item is in the condition '
            'described and is available for the agreed rental period.',
        'Customers and vendors should follow the rental dates and '
            'handover or delivery instructions communicated through '
            'the platform.',
      ],
    },
    {
      'icon': Icons.event_busy_outlined,
      'title': 'Cancellation and Refund Policy',
      'content': [
        'Cancellation requests are subject to the cancellation terms '
            'shown for the relevant rental or communicated by Attirely.',
        'Refund eligibility, processing and timelines may depend on '
            'the payment status, rental stage and applicable cancellation '
            'conditions.',
        'Customers should raise cancellation or refund concerns through '
            'the available support channel.',
        'Vendors must not promise refunds or deductions that conflict '
            'with the applicable Attirely rental terms.',
      ],
    },
    {
      'icon': Icons.account_balance_wallet_outlined,
      'title': 'Security Deposit',
      'content': [
        'A refundable security deposit may be applicable to a rental. '
            'The amount and conditions should be displayed or '
            'communicated before the rental is confirmed.',
        'The deposit is intended to provide protection against '
            'eligible loss or damage, subject to the applicable rental '
            'agreement.',
        'Deposit deductions, if any, should be supported by the '
            'applicable terms and communicated transparently.',
        'Refunds of eligible deposits are subject to the item return '
            'and verification process.',
      ],
    },
    {
      'icon': Icons.assignment_ind_outlined,
      'title': 'Vendor Responsibilities',
      'content': [
        'Vendors must maintain accurate listings and respond to '
            'customer requests within a reasonable time.',
        'Vendors must communicate item condition, size, availability '
            'and rental requirements clearly.',
        'Vendors must maintain the quality and hygiene of rental items '
            'and prepare them appropriately before handover.',
        'Vendors must follow applicable laws and the rental terms '
            'agreed with customers.',
        'Vendors must not misuse customer information or use it for '
            'unrelated purposes.',
      ],
    },
    {
      'icon': Icons.privacy_tip_outlined,
      'title': 'Privacy Policy',
      'content': [
        'Attirely may collect account, contact, store, listing, request '
            'and transaction information required to operate the '
            'platform.',
        'Information is used to provide platform services, manage '
            'accounts, facilitate rental interactions, provide support '
            'and improve the user experience.',
        'Personal information should only be accessed and used for '
            'legitimate platform-related purposes.',
        'Users should keep their login credentials confidential and '
            'notify Attirely if they suspect unauthorised account access.',
        'Information may be shared with relevant parties where needed '
            'to fulfil platform services or where required by law.',
      ],
    },
    {
      'icon': Icons.gavel_outlined,
      'title': 'Terms and Conditions',
      'content': [
        'By accessing or using Attirely, users and vendors agree to '
            'follow the applicable platform terms and policies.',
        'Users must not misuse the platform, interfere with its '
            'operation, or attempt unauthorised access.',
        'Attirely may update platform features, policies and terms '
            'from time to time. Updated terms will be made available '
            'through the platform.',
        'Continued use of the platform after an update may be subject '
            'to the revised terms, as permitted by applicable law.',
        'Attirely may restrict or suspend accounts involved in '
            'fraudulent, abusive or policy-violating activity.',
        'Any dispute will be handled in accordance with applicable '
            'laws and the relevant agreements.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: darkBurgundy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms & Policies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _introCard(),
            const SizedBox(height: 24),
            const Text(
              'POLICIES & GUIDELINES',
              style: TextStyle(
                color: burgundy,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 13),
            ...policies.map((policy) => _policyTile(policy)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EAE4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: burgundy,
                    size: 27,
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Need assistance?',
                    style: TextStyle(
                      color: darkBurgundy,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'For questions about these policies, please contact '
                        'Attirely support through the available support channel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBurgundy, Color(0xFF64172F)],
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: gold,
            size: 29,
          ),
          SizedBox(height: 15),
          Text(
            'Terms of Service',
            style: TextStyle(
              color: gold,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Clear expectations. Better experiences.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please read the following guidelines to understand '
                'how Attirely works and the responsibilities of '
                'customers and vendors.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyTile(Map<String, dynamic> policy) {
    final List<String> content =
    List<String>.from(policy['content']);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: gold.withOpacity(0.6)),
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          splashColor: burgundy.withOpacity(0.05),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            17,
            0,
            17,
            17,
          ),
          leading: Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.4),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              policy['icon'] as IconData,
              color: burgundy,
              size: 21,
            ),
          ),
          title: Text(
            policy['title'].toString(),
            style: const TextStyle(
              color: darkBurgundy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: burgundy,
          collapsedIconColor: burgundy,
          children: content.map((paragraph) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    height: 5,
                    width: 5,
                    decoration: const BoxDecoration(
                      color: burgundy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      paragraph,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
