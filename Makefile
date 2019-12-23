.PHONY: home-workstation
home-workstation:
	ln -f home-workstation/configuration.nix
	ln -f home-workstation/hardware-configuration.nix
.PHONY: work-workstation
work-workstation:
	ln -f work-workstation/configuration.nix
	ln -f work-workstation/hardware-configuration.nix
