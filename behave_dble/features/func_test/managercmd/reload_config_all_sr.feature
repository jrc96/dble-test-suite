# -*- coding=utf-8 -*-
# Copyright (C) 2016-2020 ActionTech.
# License: https://www.mozilla.org/en-US/MPL/2.0 MPL version 2 or higher.
# Created by yangxiaoliang at 2019/12/18
#2.19.11.0#dble-7856
Feature: reload @@config_all -sr

  Scenario: open transaction and execute "reload @@config_all -sr" or "reload @@config_all -s -r" will rebuild connections except connections in transaction
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
    <dataNode name="dn1" dataHost="ha_group1" database="db1"/>
    <dataNode name="dn2" dataHost="ha_group1" database="db2"/>
    <dataNode name="dn3" dataHost="ha_group1" database="db3"/>
    <dataNode name="dn4" dataHost="ha_group1" database="db4"/>
    <dataNode name="dn5" dataHost="ha_group1" database="db5"/>
    """
    Given Restart dble in "dble-1" success
    Then execute admin cmd "create database @@dataNode ='dn1,dn2,dn3,dn4'"
    # 1 execute "reload @@config_all -sr" will rebuild backend conn
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "rs_A"
      | sql            |
      | show @@backend |
    Then execute admin cmd "reload @@config_all -rs"
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "rs_B"
      | sql            |
      | show @@backend |
    Then check resultsets "rs_A" does not including resultset "rs_B" in following columns
      | column     | column_index |
      | BACKEND_ID | 1            |
      | MYSQLID    | 2            |

    #2 add dataNode, then execute "reload @@config_all -sr" will rebuild backend conn and add new backend conn
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
    <dataNode dataHost="ha_group1" database="db1" name="dn1" />
    <dataNode dataHost="ha_group2" database="db1" name="dn2" />
    <dataNode dataHost="ha_group1" database="db2" name="dn3" />
    <dataNode dataHost="ha_group2" database="db2" name="dn4" />
    <dataNode dataHost="ha_group1" database="db3" name="dn5" />
    """
    Then execute admin cmd "reload @@config_all -sr"
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "rs_C"
      | sql            |
      | show @@backend |
    Then check resultsets "rs_C" does not including resultset "rs_B" in following columns
      | column     | column_index |
      | BACKEND_ID | 1            |
      | MYSQLID    | 2            |
    Then check resultset "rs_B" has not lines with following column values
      | HOST-3      |
      | 172.100.9.6 |
    Then check resultset "rs_C" has lines with following column values
      | HOST-3      |
      | 172.100.9.5 |
      | 172.100.9.6 |

    #3 add readHost with err password and start the transaction, then execute "reload config_all -sr" will rebuild connections except connections in transaction
    Given add xml segment to node with attribute "{'tag':'root','prev':'dataNode'}" in "schema.xml"
    """
    <dataHost balance="0" maxCon="1000" minCon="10" name="ha_group1" slaveThreshold="100" >
      <heartbeat>select user()</heartbeat>
      <writeHost host="hostM1" password="111111" url="172.100.9.5:3306" user="test">
      <readHost host="hostS1" url="172.100.9.2:3306" password="errpwd" user="test"/>
      </writeHost>
    </dataHost>
    <dataHost balance="0" maxCon="1000" minCon="10" name="ha_group2" slaveThreshold="100" >
      <heartbeat>select user()</heartbeat>
      <writeHost host="hostM2" password="111111" url="172.100.9.4:3306" user="test">
      </writeHost>
    </dataHost>
    """
    Then execute sql in "dble-1" in "user" mode
      | conn   | toClose | sql                                              | db      |
      | conn_0 | false   | drop table if exists sharding_4_t1               | schema1 |
      | conn_0 | false   | create table sharding_4_t1 (id int)              | schema1 |
      | conn_0 | False   | begin                                            | schema1 |
      | conn_0 | false   | insert into sharding_4_t1 values (1),(2),(3),(4) | schema1 |
    Then execute admin cmd "reload @@config_all -rs"
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "rs_D"
      | sql            |
      | show @@backend |
    Then check resultset "rs_D" has not lines with following column values
      | HOST-3      |
      | 172.100.9.2 |
    Then check resultset "rs_D" has lines with following column values
      | HOST-3      | BORROWED-10 |
      | 172.100.9.4 | false       |
      | 172.100.9.5 | true        |
      | 172.100.9.6 | true        |
    Then check "rs_D" only has "2" connection of "172.100.9.6"
    Then execute sql in "dble-1" in "user" mode
      | conn   | toClose | sql                                    | expect      | db      |
      | conn_0 | false   | commit                                 | success     | schema1 |
      | conn_0 | true    | select * from sharding_4_t1 where id=2 | length{(1)} | schema1 |
    Given sleep "3" seconds
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "rs_E"
      | sql            |
      | show @@backend |
    Then check resultset "rs_E" has not lines with following column values
      | HOST-3      |
      | 172.100.9.6 |

    #4 start the transaction and change datanode, then execute "reload config_all -s -r" will rebuild connections except connections in transaction
    Then execute sql in "dble-1" in "user" mode
      | conn   | toClose | sql                                              | db      |
      | conn_0 | false   | drop table if exists sharding_4_t1               | schema1 |
      | conn_0 | false   | create table sharding_4_t1 (id int)              | schema1 |
      | conn_0 | False   | begin                                            | schema1 |
      | conn_0 | false   | insert into sharding_4_t1 values (1),(2),(3),(4) | schema1 |
    Given update file content "{install_dir}/dble/conf/schema.xml" in "dble-1" with sed cmds
    """
    s/172.100.9.4/172.100.9.6/g
    """
    Then execute admin cmd "reload @@config_all -r -s"
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "rs_G"
      | sql            |
      | show @@backend |
    Then check "rs_G" only has "2" connection of "172.100.9.4"
    Then check resultset "rs_G" has lines with following column values
      | HOST-3      | BORROWED-10 |
      | 172.100.9.4 | true        |
      | 172.100.9.5 | true        |
      | 172.100.9.6 | false       |
    Then execute sql in "dble-1" in "user" mode
      | conn   | toClose | sql                                      | expect      | db      |
      | conn_0 | False   | commit                                   | success     | schema1 |
      | conn_0 | true    | select * from sharding_4_t1 where id = 2 | length{(1)} | schema1 |
