# Created by zhaohongjie at 2018/11/27
Feature: test default db change right; cross db table not affected by others; and cross db sql works right

  Background: config for this test suites
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
    <schema dataNode="dn5" name="mytest" sqlMaxLimit="100">
            <table dataNode="dn1,dn2" name="test1" type="global" />
            <table dataNode="dn1,dn2,dn3,dn4" name="test2" rule="hash-four" />
    </schema>
    <schema name="testdb" sqlMaxLimit="100">
            <table dataNode="dn3,dn4" name="test1" rule="hash-two" />
            <table dataNode="dn1,dn2,dn3,dn4" name="test3" rule="hash-four" />
    </schema>
    """
    Given add xml segment to node with attribute "{'tag':'root'}" in "server.xml"
    """
    <user name="test">
        <property name="password">111111</property>
        <property name="schemas">mytest,testdb</property>
    </user>
    """
    Then execute admin cmd "reload @@config_all"

  @smoke @skip_restart
  Scenario: default db not set;cross db table not affected by others; and cross db sql works right
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                                             | expect  | db   |
      | test | 111111 | conn_0 | False   | drop table if exists test1                      | No database selected |      |
      | test | 111111 | conn_0 | False   | drop table if exists mytest.test1               | success |      |
      | test | 111111 | conn_0 | False   | drop table if exists mytest.test                | success |      |
      | test | 111111 | conn_0 | False   | drop table if exists testdb.test1               | success |      |
      | test | 111111 | conn_0 | False   | use mytest                                      | success |      |
      | test | 111111 | conn_0 | False   | create table test1(id int,c int)                | success |      |
      | test | 111111 | conn_0 | False   | use testdb                                      | success |      |
      | test | 111111 | conn_0 | False   | create table test1(id int)                      | success |      |
      | test | 111111 | conn_0 | False   | select c from mytest.test1                      | success |      |
      | test | 111111 | conn_0 | False   | select * from test1 join mytest.test1 using(id) | success |      |
      | test | 111111 | conn_0 | False   | select * from test1 join testdb.test1 using(id) | Not unique table/alias |      |
      | test | 111111 | conn_0 | False   | select * from mytest.test1 join testdb.test1 using(id) | success |      |
      | test | 111111 | conn_0 | False   | drop table test1                                | success |      |
      | test | 111111 | conn_0 | False   | select c from mytest.test1                      | success |      |
      | test | 111111 | conn_0 | True    | select c from test1     | Table 'db2.test1' doesn't exist |      |