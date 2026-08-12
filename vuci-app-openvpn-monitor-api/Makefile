include $(TOPDIR)/rules.mk

PKG_NAME:=vuci-app-openvpn-monitor-api
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/vuci-app-openvpn-monitor-api
  SECTION:=vuci
  CATEGORY:=VuCI
  SUBMENU:=Applications
  TITLE:=OpenVPN Monitoring API Endpoint
  DEPENDS:=+rpcd +libubus-lua
  PKG_TLT_NAME:=OpenVPN Monitoring API
endef

define Package/vuci-app-openvpn-monitor-api/description
  Backend API endpoint for monitoring OpenVPN server clients and disconnecting them.
endef

define Build/Compile
endef

define Package/vuci-app-openvpn-monitor-api/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/openvpn_monitor.json $(1)/usr/share/rpcd/acl.d/

	$(INSTALL_DIR) $(1)/usr/share/vuci/path.d
	$(INSTALL_DATA) ./files/usr/share/vuci/path.d/openvpn_monitor.json $(1)/usr/share/vuci/path.d/

	$(INSTALL_DIR) $(1)/usr/lib/lua/api/services
	$(INSTALL_DATA) ./files/usr/lib/lua/api/services/openvpn_monitor.lua $(1)/usr/lib/lua/api/services/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/openvpn-monitor-setup $(1)/etc/init.d/openvpn-monitor-setup
endef

$(eval $(call BuildPackage,vuci-app-openvpn-monitor-api))
