require 'spec_helper'

describe 'elasticsearch::user' do

  let :facts do {
    :operatingsystem => 'CentOS',
    :kernel => 'Linux',
    :osfamily => 'RedHat',
    :operatingsystemmajrelease => '7',
    :scenario => '',
    :common => ''
  } end

  let(:title) { 'elastic' }

  let(:pre_condition) {%q{
    class { 'elasticsearch':
      security_plugin => 'shield',
    }
  }}

  context 'with default parameters' do

    let(:params) do
      {
        :password => 'foobar',
        :roles => ['monitor', 'user']
      }
    end

    it { should contain_elasticsearch__user('elastic') }
    it { should contain_elasticsearch_user('elastic') }
    it do
      should contain_elasticsearch_user_roles('elastic').with(
        'ensure' => 'present',
        'roles'  => ['monitor', 'user']
      )
    end
  end

  describe 'collector ordering' do
    describe 'when present' do
      let(:pre_condition) {%q{
        class { 'elasticsearch':
          security_plugin => 'shield',
        }
        elasticsearch::instance { 'es-security-user': }
        elasticsearch::plugin { 'shield': instances => 'es-security-user' }
        elasticsearch::template { 'foo': content => {"foo" => "bar"} }
        elasticsearch::role { 'test_role':
          privileges => {
            'cluster' => 'monitor',
            'indices' => {
              '*' => 'all',
            },
          },
        }
      }}

      let(:params) {{
        :password => 'foobar',
        :roles => ['monitor', 'user']
      }}

      it { should contain_elasticsearch__role('test_role') }
      it { should contain_elasticsearch_role('test_role') }
      it { should contain_elasticsearch_role_mapping('test_role') }
      it { should contain_elasticsearch__plugin('shield') }
      it { should contain_elasticsearch_plugin('shield') }
      it { should contain_file(
        '/usr/share/elasticsearch/plugins/shield'
      ) }
      it { should contain_elasticsearch__user('elastic')
        .that_comes_before([
        'Elasticsearch::Template[foo]'
      ]).that_requires([
        'Elasticsearch::Plugin[shield]',
        'Elasticsearch::Role[test_role]'
      ])}

      include_examples 'instance', 'es-security-user', :systemd
      it { should contain_file('/etc/elasticsearch/es-security-user/shield') }
    end

    describe 'when absent' do
      let(:pre_condition) {%q{
        class { 'elasticsearch':
          security_plugin => 'shield',
        }
        elasticsearch::instance { 'es-security-user': }
        elasticsearch::plugin { 'shield':
          ensure => 'absent',
          instances => 'es-security-user',
        }
        elasticsearch::template { 'foo': content => {"foo" => "bar"} }
        elasticsearch::role { 'test_role':
          privileges => {
            'cluster' => 'monitor',
            'indices' => {
              '*' => 'all',
            },
          },
        }
      }}

      let(:params) {{
        :password => 'foobar',
        :roles => ['monitor', 'user']
      }}

      it { should contain_elasticsearch__role('test_role') }
      it { should contain_elasticsearch_role('test_role') }
      it { should contain_elasticsearch_role_mapping('test_role') }
      it { should contain_elasticsearch__plugin('shield') }
      it { should contain_elasticsearch_plugin('shield') }
      it { should contain_file(
        '/usr/share/elasticsearch/plugins/shield'
      ) }

      include_examples 'instance', 'es-security-user', :systemd
      # TODO: Uncomment once upstream issue is fixed.
      # https://github.com/rodjek/rspec-puppet/issues/418
      # it { should contain_elasticsearch__shield__user('elastic')
      #   .that_comes_before([
      #   'Elasticsearch::Template[foo]',
      #   'Elasticsearch::Plugin[shield]'
      # ]).that_requires([
      #   'Elasticsearch::Shield::Role[test_role]'
      # ])}
    end
  end
end
