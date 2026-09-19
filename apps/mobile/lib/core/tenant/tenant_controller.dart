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
  bool _loaded = false;
  bool _loadFailed = false;

  List<OrganizationMembership> get memberships => _memberships;
  OrganizationMembership? get active => _active;
  bool get loading => _loading;

  /// False until the first membership load has finished (or failed), so the
  /// router can hold every screen back behind a splash instead of building
  /// them with no active center.
  bool get loaded => _loaded;
  bool get loadFailed => _loadFailed;
  bool get hasMultipleOrganizations => _memberships.length > 1;

  /// Whether the active membership can use the given module (see
  /// `core/access/module_keys.dart`) - false with no active org.
  bool hasModule(String moduleKey) => _active?.hasModule(moduleKey) ?? false;

  Future<void> loadMemberships() async {
    _loading = true;
    notifyListeners();

    try {
      _memberships = await _repository.fetchMyMemberships();
      _loadFailed = false;
    } catch (_) {
      _memberships = [];
      _loadFailed = true;
    }

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
    _loaded = true;
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
    _loaded = false;
    _loadFailed = false;
    notifyListeners();
  }
}
