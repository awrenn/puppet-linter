# Telegraf configs specific to Windows
class profile::metrics::telegraf::client::windows {
  telegraf::input {
    default:
      options => [{
        'Instances' => ['*'],
      }],
    ;
    'win_perf_counters':
      options => [{
        'CountersRefreshInterval' => '1m',
        'object'                  => [
          {
            'ObjectName'  => 'Processor',
            'Instances'   => ['*'],
            'Counters'    => [
              '% Idle Time',
              '% Interrupt Time',
              '% Privileged Time',
              '% User Time',
              '% Processor Time',
              '% DPC Time',
            ],
            'Measurement' => 'win_cpu',
          },
          {
            'ObjectName'  => 'LogicalDisk',
            'Instances'   => ['*'],
            'Counters'    => [
              '% Idle Time',
              '% Disk Time',
              '% Disk Read Time',
              '% Disk Write Time',
              '% User Time',
              '% Free Space',
              'Current Disk Queue Length',
              'Free Megabytes',
            ],
            'Measurement' => 'win_disk',
          },
          {
            'ObjectName'  => 'PhysicalDisk',
            'Instances'   => ['*'],
            'Counters'    => [
              'Disk Read Bytes/sec',
              'Disk Write Bytes/sec',
              'Current Disk Queue Length',
              'Disk Reads/sec',
              'Disk Writes/sec',
              '% Disk Time',
              '% Disk Read Time',
              '% Disk Write Time',
            ],
            'Measurement' => 'win_diskio',
          },
          {
            'ObjectName'  => 'System',
            'Instances'   => ['------'],
            'Counters'    => [
              'Context Switches/sec',
              'System Calls/sec',
              'Processor Queue Length',
              'System Up Time',
            ],
            'Measurement' => 'win_system',
          },
          {
            'ObjectName'  => 'Memory',
            'Instances'   => ['------'],
            'Counters'    => [
              'Available Bytes',
              'Cache Faults/sec',
              'Demand Zero Faults/sec',
              'Page Faults/sec',
              'Pages/sec',
              'Transition Faults/sec',
              'Pool Nonpaged Bytes',
              'Pool Paged Bytes',
              'Standby Cache Reserve Bytes',
              'Standby Cache Normal Priority Bytes',
              'Standby Cache Core Bytes',
            ],
            'Measurement' => 'win_mem',
          },
          {
            'ObjectName'  => 'Paging File',
            'Instances'   => ['_Total'],
            'Counters'    => [
              '% Usage',
            ],
            'Measurement' => 'win_swap',
          },
          {
            'ObjectName'  => 'Network Interface',
            'Instances'   => ['*'],
            'Counters'    => [
              'Bytes Received/sec',
              'Bytes Sent/sec',
              'Packets Received/sec',
              'Packets Sent/sec',
              'Packets Received Discarded',
              'Packets Outbound Discarded',
              'Packets Received Errors',
              'Packets Outbound Errors',
            ],
            'Measurement' => 'win_net',
          }],
          'tagdrop'               => {
            'instance' => [
              '6to4*',
              'Bluetooth*',
              'HTTPS*',
              'isatap*',
              'Kernel*',
              'Layer*',
              'Local*',
              'Loopback*',
              'Miniport*',
              'QoS*',
              'Teredo*',
              'Virtual*',
            ],
          },
        },
      ],
    ;
  }
}
