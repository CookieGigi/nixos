{pkgs, ...}: {
  mkSkill = name: description: content:
    pkgs.writeText "SKILL.md" ''
      ---
      name: ${name}
      description: ${description}
      license: MIT
      compatibility: opencode
      metadata:
        audience: nixos-users
        domain: system-administration
      ---

      ${content}
    '';
}
