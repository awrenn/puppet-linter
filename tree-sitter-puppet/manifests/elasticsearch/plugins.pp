class profile::elasticsearch::plugins {

  Elasticsearch::Plugin {
    instances => ['plops'],
  }
  ::elasticsearch::plugin { 'mobz/elasticsearch-head':
    module_dir => 'head',
  }

  ::elasticsearch::plugin { 'karmi/elasticsearch-paramedic':
    module_dir => 'paramedic',
  }

  ::elasticsearch::plugin { 'lukas-vlcek/bigdesk':
    module_dir => 'bigdesk',
  }

  ::elasticsearch::plugin { 'lmenezes/elasticsearch-kopf/v1.5.2':
    module_dir => 'kopf',
  }

  ::elasticsearch::plugin { 'elasticsearch/elasticsearch-cloud-aws/2.5.1':
    module_dir => 'cloud-aws',
  }
}
