include $(TOPDIR)/rules.mk

PKG_NAME:=openvpn-ubus
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/openvpn-ubus
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=OpenVPN Ubus Management Interface
  DEPENDS:=+openvpn-openssl +libuci-lua +libubus-lua +libubox-lua
endef

define Package/openvpn-ubus/description
  Provides dynamic Ubus objects for managing multiple OpenVPN server instances.
endef

define Build/Compile
endef

define Package/openvpn-ubus/install
	# Nukopijuojame ubus demona
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/openvpn-ubusd.lua $(1)/usr/sbin/openvpn-ubusd

	# Nukopijuojame Init skriptą
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/openvpn-ubus.init $(1)/etc/init.d/openvpn-ubus
endef

$(eval $(call BuildPackage,openvpn-ubus))
