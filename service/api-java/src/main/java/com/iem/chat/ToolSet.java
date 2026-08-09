package com.iem.chat;

import com.iem.enums.Role;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;

public interface ToolSet {

    Set<Role> EVERYONE = EnumSet.allOf(Role.class);

    Set<Role> CITIZEN = EnumSet.of(Role.CITIZEN);

    Set<Role> COLLECTOR = EnumSet.of(Role.COLLECTOR);

    Set<Role> RECYCLER = EnumSet.of(Role.RECYCLER);

    Set<Role> ADMINS = EnumSet.of(Role.MUNICIPAL_ADMIN, Role.SUPER_ADMIN);

    Set<Role> SUPER_ADMIN = EnumSet.of(Role.SUPER_ADMIN);

    Set<Role> TRADERS = EnumSet.of(Role.CITIZEN, Role.RECYCLER);

    List<ChatTool> tools();
}
