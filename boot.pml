
mtype = { ResourceRoot, ResourceA, ResourceB, ResourceA1, ResourceA2 }
mtype = { STOPPED, BOOT_SCHEDULED, BOOT_INIT, BOOT_MAIN, BOOT_WAIT, BOOTED, BOOT_SCHEDULE_FAIL, BOOT_FAIL, BOOT_CLEANUP }

typedef Resource {
  byte status = STOPPED;
  byte boot_cnt = 0;
  byte code = 0;
  byte parent = 0;
  byte child_a = 0;
  byte child_b = 0;
}

Resource resources[9];

#define resource_root resources[ResourceRoot]
#define resource_a resources[ResourceA]
#define resource_b resources[ResourceB]
#define resource_a_1 resources[ResourceA1]
#define resource_a_2 resources[ResourceA2]

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
    printf("%d: %e r:%e a:%e b:%e a1:%e a2:%e\n", _pid, id, resource_root.status, resource_a.status, resource_b.status, resource_a_1.status, resource_a_2.status)

  }
}

inline boot_unschedule(code) {
   atomic {
     if
     :: resource_a.is_boot_scheduled && resource_a.code == code -> resource_a.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: resource_b.is_boot_scheduled && resource_b.code == code -> resource_b.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: resource_a_1.is_boot_scheduled && resource_a_1.code == code -> resource_a_1.set_stopped
     :: else skip
     fi
   }
   atomic {
     if
     :: resource_a_2.is_boot_scheduled && resource_a_2.code == code -> resource_a_2.set_stopped
     :: else skip
     fi
   }
}

inline boot_schedule(id, code, do_resource_a, do_resource_b, do_resource_a_1, do_resource_a_2) {
  if
  :: do_resource_a && id != ResourceA
     atomic {
       if
       :: resource_a.is_stopped -> resource_a.set_boot_scheduled -> resource_a.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_resource_b && id != ResourceB
     atomic {
       if
       :: resource_b.is_stopped -> resource_b.set_boot_scheduled -> resource_b.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_resource_a_1 && id != ResourceA1
     atomic {
       if
       :: resource_a_1.is_stopped -> resource_a_1.set_boot_scheduled -> resource_a_1.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  if
  :: do_resource_a_2 && id != ResourceA2
     atomic {
       if
       :: resource_a_2.is_stopped -> resource_a_2.set_boot_scheduled -> resource_a_2.code = code
       :: else _this.set_boot_schedule_fail -> goto undo
       fi
     }
  :: else skip
  fi
  
  goto end

  undo:
  _this.set_boot_schedule_fail
  boot_unschedule(code)

  end:
}

inline boot_cleanup(id, code) {
   atomic {
     if
     :: resource_a.is_boot_fail && resource_a.code == code -> resource_a.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, ResourceA)
     :: else skip
     fi
   }
   atomic {
     if
     :: resource_b.is_boot_fail && resource_b.code == code -> resource_b.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, ResourceB)
     :: else skip
     fi
   }
   atomic {
     if
     :: resource_a_1.is_boot_fail && resource_a_1.code == code -> resource_a_1.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, ResourceA1)
     :: else skip
     fi
   }
   atomic {
     if
     :: resource_a_2.is_boot_fail && resource_a_2.code == code -> resource_a_2.set_stopped
        printf("%d: %e boot cleanup %e\n", _pid, id, ResourceA2)
     :: else skip
     fi
   }
}

proctype boot(int id; int fid; byte code; bool do_resource_a; bool do_resource_b; bool do_resource_a_1; bool do_resource_a_2) {
  
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
  if
  :: no_boot_code
     printf("%d: %e boot schedule descendents\n", _pid, id)
     set_boot_code
     boot_schedule(id, code, do_resource_a, do_resource_b, do_resource_a_1, do_resource_a_2)
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
     run boot(_this.child_a, _pid, code, do_resource_a, do_resource_b, do_resource_a_1, do_resource_a_2)
  :: else skip
  fi
  if
  :: _this.has_child_b && _child_b.is_boot_scheduled && _child_b.has_code
     printf("%d: %e boot %e\n", _pid, id, _this.child_b)
     run boot(_this.child_b, _pid, code, do_resource_a, do_resource_b, do_resource_a_1, do_resource_a_2)
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

  /* if resource_root and nothing is booted set to stopped */
  if
  :: id == ResourceRoot
     printf("%d: %e check for stopped resource_a\n", _pid, id)
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
  printf("%d: %e boot fail schedule fail\n", _pid, id)
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
  resource_root.child_a = ResourceA
  resource_root.child_b = ResourceB
  resource_a.parent = ResourceRoot
  resource_a.child_a = ResourceA1
  resource_a.child_b = ResourceA2
  resource_b.parent = ResourceA
  resource_a_1.parent = ResourceA
  resource_a_2.parent = ResourceA
}

init {
  set_relations()

  run boot(ResourceRoot, -1, 0, true, true, true, true)

}

/* 

stopped - nothing happening ready to boot
boot_init - got inside the boot codes still need to check that parent status
boot_main - parent is booted/booting and now can not stop

rules

no two resources should be in boot_init at the same time

when a parent is in unboot_main a child should not be allowed in boot_main


#define q (resource_a.is_stopped && (resource_b.is_booting)
#define q (resource_a.is_stopped && (resource_a_1.is_booting)
*/

#define p (resource_a.is_stopped && resource_b.is_booted)

never  {    /* ![]!p */
T0_init:
        do
        :: atomic { ((p)) -> assert(!((p))) }
        :: (1) -> goto T0_init
        od;
accept_all:
        skip
}
