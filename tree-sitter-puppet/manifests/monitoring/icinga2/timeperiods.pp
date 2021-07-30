class profile::monitoring::icinga2::timeperiods {

  # All time periods are relative to the system time
  icinga2::object::timeperiod { 'workhours':
    ranges   => {
      monday    => '10:00-15:00',
      tuesday   => '10:00-15:00',
      wednesday => '10:00-15:00',
      thursday  => '10:00-15:00',
      friday    => '10:00-15:00',
    },
  }

  icinga2::object::timeperiod { 'extended_workhours':
    ranges   => {
      monday    => '07:00-19:00',
      tuesday   => '07:00-19:00',
      wednesday => '07:00-19:00',
      thursday  => '07:00-19:00',
      friday    => '07:00-19:00',
    },
  }

  icinga2::object::timeperiod { 'nonworkhours':
    ranges => {
      monday    => '00:00-9:59,15:00-24:00',
      tuesday   => '00:00-9:59,15:00-24:00',
      wednesday => '00:00-9:59,15:00-24:00',
      thursday  => '00:00-9:59,15:00-24:00',
      friday    => '00:00-9:59,15:00-24:00',
      saturday  => '00:00-24:00',
      sunday    => '00:00-24:00',
    },
  }

  icinga2::object::timeperiod { '24x7':
    ranges => {
      monday    => '00:00-24:00',
      tuesday   => '00:00-24:00',
      wednesday => '00:00-24:00',
      thursday  => '00:00-24:00',
      friday    => '00:00-24:00',
      saturday  => '00:00-24:00',
      sunday    => '00:00-24:00',
    },
  }

  # Atlassian apps are restarted for a potential Java timezone update every
  # Saturday at 9:55 pm PT. Search for OPS-6241 to find related code.
  icinga2::object::timeperiod { 'atlassian':
    ranges => {
      monday    => '00:00-24:00',
      tuesday   => '00:00-24:00',
      wednesday => '00:00-24:00',
      thursday  => '00:00-24:00',
      friday    => '00:00-24:00',
      saturday  => '00:00-21:55,20:10-24:00',
      sunday    => '00:00-24:00',
    },
  }
}
