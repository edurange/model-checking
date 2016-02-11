
mtype = { STOPPED, BOOT_SCHEDULED, BOOT_INIT, BOOT_MAIN, BOOT_WAIT, BOOTED, BOOT_SCHEDULE_FAIL, BOOT_FAIL, BOOT_CLEANUP, Scenario, Cloud, Subnet_A, Subnet_B, Instance_A_1, Instance_A_2, Instance_B_1, Instance_B_2 }

typedef Resource {
  byte status = STOPPED;
  byte boot_cnt = 0;
  byte code = 0;
  byte parent = 0;
  byte child_a = 0;
  byte child_b = 0;
}

Resource resources[9];

#define scenario resources[Scenario]
#define cloud resources[Cloud]
#define subnet_a resources[Subnet_A]
#define subnet_b resources[Subnet_B]
#define instance_a_1 resources[Instance_A_1]
#define instance_a_2 resources[Instance_A_2]
#define instance_b_1 resources[Instance_B_1]
#define instance_b_2 resources[Instance_B_2]

#define _this resources[id]
#define _parent resources[resources[id].parent]
#define _child_a resources[resources[id].child_a]
#define _child_b resources[resources[id].child_b]

#define _this_can_boot _this.is_stopped || (_this.is_boot_scheduled && _this.code == code)
#define _parent_is_booting _parent.status >= BOOTED && _parent.status <= BOOT_SCHEDULED
#define _child_a_is_booting _child_a.status >= BOOTED && _child_a.status <= BOOT_SCHEDULED
#define _child_b_is_booting _child_b.status >= BOOTED && _child_b.status <= BOOT_SCHEDULED

#define has_parent parent != 0
#define has_child_a child_a != 0
#define has_child_b child_b != 0

#define is_stopped status == STOPPED
#define is_boot_scheduled status == BOOT_SCHEDULED
#define is_boot_schedule_fail status == BOOT_SCHEDULE_FAIL
#define is_booted status == BOOTED
#define is_boot_wait status == BOOT_WAIT
#define is_boot_fail status == BOOT_FAIL

#define has_code code == code
#define not_booted status != BOOTED

#define set_stopped status = STOPPED
#define set_booted status = BOOTED
#define set_boot_scheduled status = BOOT_SCHEDULED
#define set_boot_schedule_fail status = BOOT_SCHEDULE_FAIL
#define set_boot_init status = BOOT_INIT
#define set_boot_wait status = BOOT_WAIT
#define set_boot_fail status = BOOT_FAIL

#define set_boot_code if :: code == 0 -> code = _pid :: else skip fi

#define no_boot_code code == 0
#define reset_code code = 0

inline print_status(id) {
  atomic {
    printf("%d: %e s:%e c:%e sa:%e sb:%e i1:%e i2:%e i3:%e i4:%e\n", _pid, id, scenario.status, cloud.status, subnet_a.status, subnet_b.status, instance_a_1.status, instance_a_2.status, instance_b_1.status, instance_b_2.status)

  }
}

inline boot_unschedule(code) {
   atomic {
     if
     :: cloud.is_boot_scheduled && cloud.code == code -> cloud.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: subnet_a.is_boot_scheduled && subnet_a.code == code -> subnet_a.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: subnet_b.is_boot_scheduled && subnet_b.code == code -> subnet_b.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_a_1.is_boot_scheduled && instance_a_1.code == code -> instance_a_1.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_a_2.is_boot_scheduled && instance_a_2.code == code -> instance_a_2.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_b_1.is_boot_scheduled && instance_b_1.code == code -> instance_b_1.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_b_2.is_boot_scheduled && instance_b_2.code == code -> instance_b_2.set_stopped
     :: else skip
     fi
   }
}

inline boot_schedule(id, code, do_scenario, do_cloud, do_subnet_a, do_subnet_b, do_instance_a_1, do_instance_a_2, do_instance_b_1, do_instance_b_2) {
  if
  :: do_cloud && id != Cloud
     atomic {
       if
       :: cloud.is_stopped -> cloud.set_boot_scheduled -> cloud.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_subnet_a && id != Subnet_A
     atomic {
       if
       :: subnet_a.is_stopped -> subnet_a.set_boot_scheduled -> subnet_a.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_subnet_b && id != Subnet_B
     atomic {
       if
       :: subnet_b.is_stopped -> subnet_b.set_boot_scheduled -> subnet_b.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_instance_a_1 && id != Instance_A_1
     atomic {
       if
       :: instance_a_1.is_stopped -> instance_a_1.set_boot_scheduled -> instance_a_1.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_instance_a_2 && id != Instance_A_2
     atomic {
       if
       :: instance_a_2.is_stopped -> instance_a_2.set_boot_scheduled -> instance_a_2.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_instance_b_1 && id != Instance_B_1
     atomic {
       if
       :: instance_b_1.is_stopped -> instance_b_1.set_boot_scheduled -> instance_b_1.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_instance_b_2 && id != Instance_B_2
     atomic {
       if
       :: instance_b_2.is_stopped -> instance_b_2.set_boot_scheduled -> instance_b_2.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi

  goto end

  undo:
  boot_unschedule(code)

  end:
}

inline boot_cleanup(id, code) {
   atomic {
     if
     :: cloud.is_boot_fail && cloud.code == code -> cloud.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, Cloud)
     :: else skip
     fi
   }
   atomic {
     if
     :: subnet_a.is_boot_fail && subnet_a.code == code -> subnet_a.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, Subnet_A)
     :: else skip
     fi
   }
   atomic {
     if
     :: subnet_b.is_boot_fail && subnet_b.code == code -> subnet_b.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, Subnet_B)
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_a_1.is_boot_fail && instance_a_1.code == code -> instance_a_1.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, Instance_A_1)
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_a_2.is_boot_fail && instance_a_2.code == code -> instance_a_2.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, Instance_A_2)
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_b_1.is_boot_fail && instance_b_1.code == code -> instance_b_1.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, Instance_B_1)
     :: else skip
     fi
   }
   atomic {
     if
     :: instance_b_2.is_boot_fail && instance_b_2.code == code -> instance_b_2.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, Instance_B_2)
     :: else skip
     fi
   }
}

proctype boot(int id; int fid; byte code; bool do_scenario; bool do_cloud; bool do_subnet_a; bool do_subnet_b; bool do_instance_a_1; bool do_instance_a_2; bool do_instance_b_1; bool do_instance_b_2) {
  
  bool is_root = (no_boot_code -> true : false)

  /* only allow one process at a time in boot */
  printf("%d:%d %e boot try\n", _pid, fid, id)
  atomic {
    if
    :: _this_can_boot
       _this.set_boot_init
       _this.boot_cnt++
    :: else goto fail_enter
    fi
  }

  /* check that parent is booted or booting */
  if
  :: _this.has_parent
     printf("%d: %e boot check parent booting\n", _pid, id)
     if
     :: _parent_is_booting
     :: else goto fail_parent_booting
     fi
  :: else skip
  fi

  /* wait for parent. fail if parent fails */
  if
  :: _this.has_parent
     printf("%d: %e boot wait for parent\n", _pid, id)
     if
     :: _parent.not_booted
        do
        :: _parent.is_booted || _parent.is_boot_wait -> break
        :: _parent.is_boot_fail -> goto fail_parent_wait
        od
     :: else skip
     fi
  :: else skip
  fi

  /* set boot code and schedule descendents, fail if can't schedule all */
  printf("%d: %e boot schedule descendents\n", _pid, id)
  if
  :: no_boot_code
     set_boot_code
     boot_schedule(id, code, do_scenario, do_cloud, do_subnet_a, do_subnet_b, do_instance_a_1, do_instance_a_2, do_instance_b_1, do_instance_b_2)
     if
     :: _this.is_boot_schedule_fail -> goto fail_schedule
     :: else skip
     fi
  :: else skip
  fi

  /* succeed or fail */
  if
  :: _this.set_boot_fail -> goto fail_main
  :: _this.set_boot_wait
  fi

  /* boot chilren */
  if
  :: _this.has_child_a && _child_a.is_boot_scheduled && _child_a.has_code
     printf("%d: %e boot %e\n", _pid, id, _this.child_a)
     run boot(_this.child_a, _pid, code, do_scenario, do_cloud, do_subnet_a, do_subnet_b, do_instance_a_1, do_instance_a_2, do_instance_b_1, do_instance_b_2)
  :: else skip
  fi
  if
  :: _this.has_child_b && _child_b.is_boot_scheduled && _child_b.has_code
     printf("%d: %e boot %e\n", _pid, id, _this.child_b)
     run boot(_this.child_b, _pid, code, do_scenario, do_cloud, do_subnet_a, do_subnet_b, do_instance_a_1, do_instance_a_2, do_instance_b_1, do_instance_b_2)
  :: else skip
  fi

  /* wait for children */
  if
  :: _this.has_child_a && _child_a.has_code
     printf("%d: %e boot wait child %e\n", _pid, id, _this.child_a)
     do
     :: _child_a.is_booted || _child_a.is_boot_fail -> break
     od 
  :: else skip
  fi
  if
  :: _this.has_child_b && _child_b.has_code
     printf("%d: %e boot wait child %e\n", _pid, id, _this.child_b)
     do
     :: _child_b.is_booted || _child_b.is_boot_fail -> break
     od 
  :: else skip
  fi

  /* check all descendents for failure set stopped if failed unschedule if needed */
  if
  :: is_root
     boot_cleanup(id, code)
     boot_unschedule(code)
  :: else skip
  fi

  /* if scenario and nothing is booted set to stopped */
  if
  :: id == Scenario
     printf("%d: %e check for stopped cloud\n", _pid, id)
     if
     :: _this.has_child_a && _child_a.is_stopped && _this.has_child_b && _child_b.is_stopped -> goto fail_main
     :: _this.has_child_a && _child_a.is_stopped && !(_this.has_child_b) -> goto fail_main
     :: _this.has_child_b && _child_b.is_stopped && !(_this.has_child_a) -> goto fail_main
     :: else _this.set_booted
     fi
  :: else _this.set_booted
  fi
  
  printf("%d: %e boot success\n", _pid, id)
  goto end

  fail_enter:
  printf("%d: %e boot fail enter\n", _pid, id)
  goto end

  fail_parent_booting:
  printf("%d: %e boot fail parent not booting\n", _pid, id)
  goto end

  fail_parent_wait:
  printf("%d: %e boot fail parent boot fail\n", _pid, id)
  goto end

  fail_schedule:
  printf("%d: %e boot fail parent boot fail\n", _pid, id)
  goto end

  fail_main:
  printf("%d: %e boot fail main\n", _pid, id)
  if 
  :: is_root
     boot_unschedule(code)
     _this.set_stopped
  :: else skip
  fi
  goto end

  end:
  print_status(id)
}

inline set_relations() {
  scenario.child_a = Cloud
  cloud.parent = Scenario
  cloud.child_a = Subnet_A
  cloud.child_b = Subnet_B
  subnet_a.parent = Cloud
  subnet_a.child_a = Instance_A_1
  subnet_a.child_b = Instance_A_2
  subnet_b.parent = Cloud
  subnet_b.child_a = Instance_B_1
  subnet_b.child_b = Instance_B_2
  instance_a_1.parent = Subnet_A
  instance_a_2.parent = Subnet_A
  instance_b_1.parent = Subnet_B
  instance_b_2.parent = Subnet_B
}

init {
  set_relations()

  /* run boot(Scenario, -1, -1, true, true, true, true, true, true, true, true) */
  run boot(Scenario, -1, 0, true, true, true, true, true, true, true, false)

}

/* 

stopped - nothing happening ready to boot
boot_init - got inside the boot codes still need to check that parent status
boot_main - parent is booted/booting and now can not stop

rules

no two resources should be in boot_init at the same time

when a parent is in unboot_main a child should not be allowed in boot_main


#define q (cloud.is_stopped && (subnet_a.is_booting)
#define q (cloud.is_stopped && (subnet_b.is_booting)
*/

#define p (cloud.is_stopped && subnet_a.is_booted)

never  {    /* ![]!p */
T0_init:
        do
        :: atomic { ((p)) -> assert(!((p))) }
        :: (1) -> goto T0_init
        od;
accept_all:
        skip
}
