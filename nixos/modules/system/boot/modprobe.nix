{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  # A list of attrnames is coerced into an attrset of bools by
  # setting the values to true.
  attrNamesToTrue = types.coercedTo (types.listOf types.str) (
    enabledList: lib.genAttrs enabledList (_attrName: true)
  ) (types.attrsOf types.bool);

in

{

  ###### interface

  options = {
    boot.modprobeConfig.enable =
      mkEnableOption "modprobe config. This is useful for systems like containers which do not require a kernel"
      // {
        default = true;
      };

    boot.modprobeConfig.useUbuntuModuleBlacklist =
      mkEnableOption "Ubuntu distro's module blacklist"
      // {
        default = true;
      };

    boot.blacklistedKernelModules = mkOption {
      type = attrNamesToTrue;
      default = { };
      example = [
        "cirrusfb"
        "i2c_piix4"
      ];
      description = ''
        Set of names of kernel modules that should not be loaded
        automatically by the hardware probing code. This can either be
        a list of modules or an attrset. In an attrset, names that are
        set to `true` represent modules that will be blacklisted.
      '';
      apply = mods: lib.attrNames (lib.filterAttrs (_: v: v) mods);
    };

    boot.extraModprobeConfig = mkOption {
      default = "";
      example = ''
        options parport_pc io=0x378 irq=7 dma=1
      '';
      description = ''
        Any additional configuration to be appended to the generated
        {file}`modprobe.conf`.  This is typically used to
        specify module options.  See
        {manpage}`modprobe.d(5)` for details.
      '';
      type = types.lines;
    };

  };

  ###### implementation

  config = mkIf config.boot.modprobeConfig.enable {

    environment.etc."modprobe.d/ubuntu.conf" =
      mkIf config.boot.modprobeConfig.useUbuntuModuleBlacklist
        {
          source = "${pkgs.kmod-blacklist-ubuntu}/modprobe.conf";
        };

    environment.etc."modprobe.d/nixos.conf".text = ''
      ${flip concatMapStrings config.boot.blacklistedKernelModules (name: ''
        blacklist ${name}
      '')}
      ${config.boot.extraModprobeConfig}
    '';
    environment.etc."modprobe.d/debian.conf".source = pkgs.kmod-debian-aliases;

    environment.etc."modprobe.d/systemd.conf".source =
      "${config.systemd.package}/lib/modprobe.d/systemd.conf";

    environment.systemPackages = [ pkgs.kmod ];

    system.activationScripts.modprobe = stringAfter [ "specialfs" ] ''
      # Allow the kernel to find our wrapped modprobe (which searches
      # in the right location in the Nix store for kernel modules).
      # We need this when the kernel (or some module) auto-loads a
      # module.
      echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe
    '';

  };

}
