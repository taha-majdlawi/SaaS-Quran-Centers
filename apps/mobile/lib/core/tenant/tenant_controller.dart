import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'organization.dart';
import 'tenant_repository.dart';

/// Holds which organization (center) is currently active, and every
/// organization the signed-in user could switch to. Replaces the
/// build-time, single-center assumption baked into eqraa_app - branding,
/// role-guarded routes, and every data query key off `activeMembership`.
class TenantController extends ChangeNotifier {
  TenantController(this._repository);

  static const _activeOrgPrefKey = 'active_organization_id';

  final TenantRepository _repository;

  List<OrganizationMembership> _memberships = [];
  OrganizationMembership? _active;
  bool _loading = false;

  List<OrganizationMembership> get memberships => _memberships;
  OrganizationMembership? get active => _active;
  bool get loading => _loading;
  bool get hasMultipleOrganizations => _memberships.length > 1;

  Future<void> loadMemberships() async {
    _loading = true;
    notifyListeners();

    _memberships = await _repository.fetchMyMemberships();

    if (_memberships.isEmpty) {
      _active = null;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final savedOrgId = prefs.getString(_activeOrgPrefKey);
      _active = _memberships.firstWhere(
        (m) => m.organization.id == savedOrgId,
        orElse: () => _memberships.first,
      );
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> switchTo(OrganizationMembership membership) async {
    _active = membership;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeOrgPrefKey, membership.organization.id);
    notifyListeners();
  }

  void clear() {
    _memberships = [];
    _active = null;
    notifyListeners();
  }
}
