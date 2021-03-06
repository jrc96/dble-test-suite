# Copyright (C) 2016-2020 ActionTech.
# License: https://www.mozilla.org/en-US/MPL/2.0 MPL version 2 or higher.
# Created by maofei at 2018/11/6
Feature: show @@connection.sql test

  Background: prepare env
    Given delete the following xml segment
      |file        | parent          | child               |
      |schema.xml  |{'tag':'root'}   | {'tag':'schema'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataNode'}  |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}  |
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
        <schema dataNode="dn1" name="schema1" sqlMaxLimit="100">
            <table dataNode="dn1,dn2,dn3,dn4" name="test" type="global" />
        </schema>
        <dataNode dataHost="ha_test" database="db1" name="dn1" />
        <dataNode dataHost="ha_test" database="db2" name="dn2" />
        <dataNode dataHost="ha_test" database="db3" name="dn3" />
        <dataNode dataHost="ha_test" database="db4" name="dn4" />
        <dataHost balance="0" maxCon="9" minCon="3" name="ha_test" >
            <heartbeat>select user()</heartbeat>
            <writeHost host="hostM1" password="111111" url="172.100.9.1:3306" user="test">
            </writeHost>
        </dataHost>
    """
    Given Restart dble in "dble-1" success
    Then execute admin cmd "create database @@dataNode ='dn1,dn2,dn3,dn4'"

  @TRIVIAL
  Scenario: query execute time <1ms #1
    Then execute sql in "dble-1" in "user" mode
      | sql                    | db       |
      | select sleep(0.0001)   | schema1  |
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "conn_rs_A"       
      | sql                   |       
      | show @@connection.sql |
    Then removal result set "conn_rs_A" contains "@@connection" part
    Given sleep "2" seconds
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "conn_rs_B"
      | sql                   |
      | show @@connection.sql |
    Then removal result set "conn_rs_B" contains "@@connection" part
    Then check resultsets "conn_rs_A" and "conn_rs_B" are same in following columns
      |column              | column_index |
      |START_TIME          | 4            |
      |EXECUTE_TIME        | 5            |
      |SQL                 | 6            |

  @TRIVIAL
  Scenario: query execute time >1ms #2
    Then execute sql in "dble-1" in "user" mode
      | sql               | db       |
      | select sleep(0.1) | schema1  |
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "conn_rs_C"
      | sql                   |
      | show @@connection.sql |
    Then removal result set "conn_rs_C" contains "@@connection" part
    Given sleep "2" seconds
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "conn_rs_D"
      | sql                   |
      | show @@connection.sql |
    Then removal result set "conn_rs_D" contains "@@connection" part
    Then check resultsets "conn_rs_C" and "conn_rs_D" are same in following columns
      |column              | column_index |
      |START_TIME          | 4              |
      |EXECUTE_TIME        | 5              |
      |SQL                 | 6              |

  @TRIVIAL
  Scenario: multiple session with multiple query display #3
    Then execute sql in "dble-1" in "user" mode
      | sql              | expect  | db       |
      | select sleep(1)  | success | schema1   |
      | select sleep(0.1)| success | schema1   |
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "conn_rs_E"
      | sql                   |
      | show @@connection.sql |
    Then removal result set "conn_rs_E" contains "@@connection" part
    Given sleep "2" seconds
    Given execute single sql in "dble-1" in "admin" mode and save resultset in "conn_rs_F"
      | sql                   |
      | show @@connection.sql |
    Then removal result set "conn_rs_F" contains "@@connection" part
    Then check resultsets "conn_rs_E" and "conn_rs_F" are same in following columns
      |column              | column_index |
      |START_TIME          | 4              |
      |EXECUTE_TIME        | 5              |
      |SQL                 | 6              |