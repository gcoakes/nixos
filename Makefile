.PHONY: home-workstation
home-workstation:
	ln -f home-workstation/configuration.nix
	ln -f home-workstation/hardware-configuration.nix
.PHONY: work-workstation
work-workstation:
	ln -f work-workstation/configuration.nix
	ln -f work-workstation/hardware-configuration.nix
.PHONY: laptop
laptop:
	ln -f laptop/configuration.nix
	ln -f laptop/hardware-configuration.nix
.PHONY: lenovo-laptop
lenovo-laptop:
	ln -f lenovo-laptop/configuration.nix
	ln -f lenovo-laptop/hardware-configuration.nix
