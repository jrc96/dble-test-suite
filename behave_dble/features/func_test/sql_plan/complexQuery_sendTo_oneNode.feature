# -*- coding=utf-8 -*-
# Copyright (C) 2016-2019 ActionTech.
# License: https://www.mozilla.org/en-US/MPL/2.0 MPL version 2 or higher.
# Created by yangxiaoliang at 2020/1/9

#2.20.04.04#dble-8184
Feature: following complex queries are able to send one datanode
      #1.explain select count(*) from sharding_two_node a where a.id =1;
      #2.explain select * from sharding_two_node a join sharding_two_node2 b on a.id = b.id where a.id =1 and b.id=1;
      #3.explain select * from sharding_two_node a join schema2.sharding_two_node2 b on a.c_flag=b.c_flag where a.id =1 and b.id=2;
      #4.explain select * from sharding_two_node a join sharding_two_node2 b on a.c_flag=b.c_flag where (a.id =1 and b.id=1) or (a.id =2 and b.id=2);
      #5.explain select * from sharding_two_node a join sharding_two_node2 b on a.id = b.id where a.id =1;
      #6.explain select * from sharding_two_node a join sharding_two_node2 b where a.id = b.id and a.id =1;
      #7.explain select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 ));
      #8.explain select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and a.c_decimal=1 and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 ));
      #9.explain select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and (a.c_decimal=1 and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 )));
      #10.explain select * from sharding_two_node where id =1 and c_flag = (select c_flag from sharding_two_node2 where id =1 );
      #11.explain select * from sharding_two_node a where a.id =1 and exists(select * from sharding_two_node2 b where a.c_flag=b.c_flag and b.id =1);
      #12.explain select * from sharding_two_node where id =1 union select * from sharding_two_node2 where id =1 ;

  Scenario: execute "explain sql" and check result #1
    Given add xml segment to node with attribute "{'tag':'user','kv_map':{'name':'test'}}" in "server.xml"
    """
    <property name="schemas">schema1,schema2</property>
    """
    Given add xml segment to node with attribute "{'tag':'root'}" in "rule.xml"
    """
    <function name="two-long" class="Hash">
    <property name="partitionCount">2</property>
    <property name="partitionLength">512</property>
    </function>
    <function name="three-long" class="Hash">
    <property name="partitionCount">3</property>
    <property name="partitionLength">10</property>
    </function>
    """
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
    <schema name="schema1" sqlMaxLimit="100" dataNode="dn5">
    <table name="a_three" cacheKey="id" dataNode="dn1,dn2,dn3" rule="hash-three" />
    <table name="test_global" dataNode="dn1,dn2,dn3" type="global"/>
    <table name="aly_test" dataNode="dn1,dn2,dn3,dn4" rule="hash-four" />
    <table name="aly_order" dataNode="dn1,dn2,dn3,dn4" rule="hash-four" />
    <table name="a_manager" cacheKey="id" dataNode="dn2,dn1,dn4,dn3" rule="hash-four" />
    <table name="sharding_two_node" dataNode="dn1,dn2" rule="hash-two"/>
    <table name="sharding_two_node2" dataNode="dn1,dn2" rule="hash-two"/>
    </schema>
    <schema name="schema2" sqlMaxLimit="100">
    <table name="tb_test" dataNode="dn1,dn2,dn3,dn4" rule="hash-four" />
    </schema>
    """
    Given Restart dble in "dble-1" success
    Then execute sql in "dble-1" in "user" mode
      | conn   | toClose | sql                                                                                    | expect  | db     |
      | conn_1 | False   | drop table if exists tb_test                                                           | success | schema2 |
      | conn_1 | True    | create table tb_test(id int, c char(5))                                                | success | schema2 |
      | conn_0 | False   | drop table if exists aly_test                                                          | success | schema1 |
      | conn_0 | False   | create table aly_test(id int, c char(5))                                               | success | schema1 |
      | conn_0 | False   | drop table if exists aly_order                                                         | success | schema1 |
      | conn_0 | False   | create table aly_order(id int, c char(5))                                              | success | schema1 |
      | conn_0 | False   | drop table if exists a_manager                                                         | success | schema1 |
      | conn_0 | False   | create table a_manager(id int, c char(5))                                              | success | schema1 |
      | conn_0 | False   | drop table if exists a_three                                                           | success | schema1 |
      | conn_0 | False   | create table a_three(id int, c char(5))                                                | success | schema1 |
      | conn_0 | False   | drop table if exists test_global                                                       | success | schema1 |
      | conn_0 | False   | create table test_global(id int, cc char(5))                                           | success | schema1 |
      | conn_0 | False   | insert into aly_test values(1,'a'),(1,'b'),(null,'c'),(2,'d'),(3,'c'),(4,'d'),(4,null) | success | schema1 |
      | conn_0 | False   | insert into aly_order values(1,'a'),(1,'b'),(null,null),(2,'b'),(3,'c'),(4,'e')        | success | schema1 |
      | conn_0 | False   | insert into a_manager values(1,'a'),(null,'b'),(2,'a'),(3, 'c'),(4,'d')                | success | schema1 |
      | conn_0 | False   | insert into a_three values(1,'a'),(null,'b'),(9,'b'),(10,'c'),(11,'d')                 | success | schema1 |
      | conn_0 | False   | drop table if exists sharding_two_node2                                                | success | schema1 |
      | conn_0 | False   | create table sharding_two_node2(id int, c_flag int, c_decimal float)                   | success | schema1 |
      | conn_0 | False   | drop table if exists sharding_two_node                                                 | success | schema1 |
      | conn_0 | False   | create table sharding_two_node(id int, c_flag int, c_decimal float)                    | success | schema1 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_1"
      | conn   | toClose | sql                                                         |
      | conn_0 | False   | explain select count(*) from aly_test a where a.id =1|
    Then check resultset "rs_1" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                |
      | dn2         | BASE SQL | SELECT COUNT(*) FROM aly_test a WHERE a.id = 1 LIMIT 100 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_2"
      | conn   | toClose | sql                                                              |
      | conn_0 | False   | explain select id a from sharding_two_node b where b.id=1|
    Then check resultset "rs_2" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                        |
      | dn1         | BASE SQL | SELECT id AS a FROM sharding_two_node b WHERE b.id = 1 LIMIT 100 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_3"
      | conn   | toClose | sql                                                              |
      | conn_0 | False   | explain select count(*) from aly_test a where a.id=1      |
    Then check resultset "rs_3" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                |
      | dn2         | BASE SQL | SELECT COUNT(*) FROM aly_test a WHERE a.id = 1 LIMIT 100 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_4"
      | conn   | toClose | sql                                                              |
      | conn_0 | False   | explain select count(*) from aly_test a where a.c='a' or a.c='b' and a.id =1 |
    Then check resultset "rs_4" has lines with following column values
      | DATA_NODE-0     | TYPE-1        | SQL/REF-2                                                                                                                        |
      | dn1_0           | BASE SQL      | select COUNT(*) as `_$COUNT$_rpda_0` from  `aly_test` `a` where ((`a`.`c` = 'b') AND (`a`.`id` = 1)) OR (a.c IN ('a')) LIMIT 100 |
      | dn2_0           | BASE SQL      | select COUNT(*) as `_$COUNT$_rpda_0` from  `aly_test` `a` where ((`a`.`c` = 'b') AND (`a`.`id` = 1)) OR (a.c IN ('a')) LIMIT 100 |
      | dn3_0           | BASE SQL      | select COUNT(*) as `_$COUNT$_rpda_0` from  `aly_test` `a` where ((`a`.`c` = 'b') AND (`a`.`id` = 1)) OR (a.c IN ('a')) LIMIT 100 |
      | dn4_0           | BASE SQL      | select COUNT(*) as `_$COUNT$_rpda_0` from  `aly_test` `a` where ((`a`.`c` = 'b') AND (`a`.`id` = 1)) OR (a.c IN ('a')) LIMIT 100 |
      | merge_1         | MERGE         | dn1_0; dn2_0; dn3_0; dn4_0                                                                                                       |
      | aggregate_1     | AGGREGATE     | merge_1                                                                                                                          |
      | limit_1         | LIMIT         | aggregate_1                                                                                                                      |
      | shuffle_field_1 | SHUFFLE_FIELD | limit_1                                                                                                                          |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_5"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select count(*) from aly_test a where a.id =1 group by id |
    Then check resultset "rs_5" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                            |
      | dn2         | BASE SQL | SELECT COUNT(*) FROM aly_test a WHERE a.id = 1 GROUP BY id LIMIT 100 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_6"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_order join test_global where aly_order.id in ( select id from aly_test where id=1) |
    Then check resultset "rs_6" has lines with following column values
      | DATA_NODE-0                | TYPE-1                   | SQL/REF-2                                                                               |
      | dn1_0                      | BASE SQL                 | select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` ORDER BY `aly_order`.`id` ASC |
      | dn2_0                      | BASE SQL                 | select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` ORDER BY `aly_order`.`id` ASC |
      | dn3_0                      | BASE SQL                 | select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` ORDER BY `aly_order`.`id` ASC |
      | dn4_0                      | BASE SQL                 | select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` ORDER BY `aly_order`.`id` ASC |
      | merge_and_order_1          | MERGE_AND_ORDER          | dn1_0; dn2_0; dn3_0; dn4_0                                                              |
      | shuffle_field_1            | SHUFFLE_FIELD            | merge_and_order_1                                                                       |
#      | dn1_1                      | BASE SQL                 | select `test_global`.`id`,`test_global`.`cc` from  `test_global`                                                               |
#      | merge_1                    | MERGE                    | dn1_1                                                                                                                          |
      | join_1                     | JOIN                     | shuffle_field_1; merge_1                                                                |
      | shuffle_field_2            | SHUFFLE_FIELD            | join_1                                                                                  |
#      | dn2_1                      | BASE SQL                 | select DISTINCT `aly_test`.`id` as `autoalias_scalar` from  `aly_test` where `aly_test`.`id` = 1 ORDER BY autoalias_scalar ASC |
#      | merge_2                    | MERGE                    | dn2_1                                                                                                                          |
      | distinct_1                 | DISTINCT                 | merge_2                                                                                 |
      | shuffle_field_4            | SHUFFLE_FIELD            | distinct_1                                                                              |
      | rename_derived_sub_query_1 | RENAME_DERIVED_SUB_QUERY | shuffle_field_4                                                                         |
      | shuffle_field_5            | SHUFFLE_FIELD            | rename_derived_sub_query_1                                                              |
      | join_2                     | JOIN                     | shuffle_field_2; shuffle_field_5                                                        |
      | shuffle_field_3            | SHUFFLE_FIELD            | join_2                                                                                  |


    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_7"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_order where id=(select 1) |
    Then check resultset "rs_7" has lines with following column values
      | DATA_NODE-0        | TYPE-1           | SQL/REF-2 |
#      | dn1_0              | BASE SQL              | select 1 as `autoalias_scalar`                                                                                             |
#      | merge_1            | MERGE                 | dn1_0                                                                                                                      |
      | scalar_sub_query_1 | SCALAR_SUB_QUERY | merge_1   |
#      | dn1_1              | BASE SQL(May No Need) | scalar_sub_query_1; select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` where `aly_order`.`id` = '{NEED_TO_REPLACE}' |
#      | dn2_0              | BASE SQL(May No Need) | scalar_sub_query_1; select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` where `aly_order`.`id` = '{NEED_TO_REPLACE}' |
#      | dn3_0              | BASE SQL(May No Need) | scalar_sub_query_1; select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` where `aly_order`.`id` = '{NEED_TO_REPLACE}' |
#      | dn4_0              | BASE SQL(May No Need) | scalar_sub_query_1; select `aly_order`.`id`,`aly_order`.`c` from  `aly_order` where `aly_order`.`id` = '{NEED_TO_REPLACE}' |
#      | merge_2            | MERGE                 | dn1_1; dn2_0; dn3_0; dn4_0                                                                                                 |
      | shuffle_field_1    | SHUFFLE_FIELD    | merge_2   |


    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_8"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join aly_order b on a.id = b.id where a.id =1 and b.id=1 |
    Then check resultset "rs_8" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                         |
      | dn2         | BASE SQL | select * from aly_test a join aly_order b on a.id = b.id where a.id =1 and b.id=1 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_9"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join a_manager b on a.id = b.id where a.id =1 and b.id=1 |
    Then check resultset "rs_9" has lines with following column values
      | DATA_NODE-0     | TYPE-1        | SQL/REF-2                                                                                                   |
      | dn2_0           | BASE SQL      | select `a`.`id`,`a`.`c` from  `aly_test` `a` where (`a`.`id` = 1) AND (`a`.`id` = 1) ORDER BY `a`.`id` ASC  |
      | merge_1         | MERGE         | dn2_0                                                                                                       |
      | shuffle_field_1 | SHUFFLE_FIELD | merge_1                                                                                                     |
      | dn1_0           | BASE SQL      | select `b`.`id`,`b`.`c` from  `a_manager` `b` where (`b`.`id` = 1) AND (`b`.`id` = 1) ORDER BY `b`.`id` ASC |
      | merge_2         | MERGE         | dn1_0                                                                                                       |
      | shuffle_field_3 | SHUFFLE_FIELD | merge_2                                                                                                     |
      | join_1          | JOIN          | shuffle_field_1; shuffle_field_3                                                                            |
      | shuffle_field_2 | SHUFFLE_FIELD | join_1                                                                                                      |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_10"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join a_three b on a.c = b.c where a.id =4 and b.id=2 |
    Then check resultset "rs_10" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                     |
      | dn1         | BASE SQL | select * from aly_test a join a_three b on a.c = b.c where a.id =4 and b.id=2 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_11"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join a_three b on a.c = b.c where a.id =4 and b.id=10 |
    Then check resultset "rs_11" has lines with following column values
      | DATA_NODE-0     | TYPE-1        | SQL/REF-2                                                                            |
      | dn1_0           | BASE SQL      | select `a`.`id`,`a`.`c` from  `aly_test` `a` where `a`.`id` = 4 ORDER BY `a`.`c` ASC |
      | merge_1         | MERGE         | dn1_0                                                                                |
      | shuffle_field_1 | SHUFFLE_FIELD | merge_1                                                                              |
      | dn2_0           | BASE SQL      | select `b`.`id`,`b`.`c` from  `a_three` `b` where `b`.`id` = 10 ORDER BY `b`.`c` ASC |
      | merge_2         | MERGE         | dn2_0                                                                                |
      | shuffle_field_3 | SHUFFLE_FIELD | merge_2                                                                              |
      | join_1          | JOIN          | shuffle_field_1; shuffle_field_3                                                     |
      | shuffle_field_2 | SHUFFLE_FIELD | join_1                                                                               |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_12"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join a_three b on a.c = b.c where a.id =4 and b.id=2 and b.c='a' |
    Then check resultset "rs_12" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                                 |
      | dn1         | BASE SQL | select * from aly_test a join a_three b on a.c = b.c where a.id =4 and b.id=2 and b.c='a' |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_13"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a,  test_global where a.c=test_global.cc and a.id =3 and test_global.id=1 |
    Then check resultset "rs_13" has lines with following column values
      | DATA_NODE-0     | TYPE-1        | SQL/REF-2                |
#      | dn4_0           | BASE SQL      | select `a`.`id`,`a`.`c` from  `aly_test` `a` where `a`.`id` = 3 ORDER BY `a`.`c` ASC                                          |
#      | merge_1         | MERGE         | dn4_0                                                                                                                         |
      | shuffle_field_1 | SHUFFLE_FIELD | merge_1                  |
#      | dn2_0           | BASE SQL      | select `test_global`.`id`,`test_global`.`cc` from  `test_global` where `test_global`.`id` = 1 order by `test_global`.`cc` ASC |
#      | merge_2         | MERGE         | dn2_0                                                                                                                         |
      | join_1          | JOIN          | shuffle_field_1; merge_2 |
      | shuffle_field_2 | SHUFFLE_FIELD | join_1                   |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_14"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join schema2.tb_test b on a.c=b.c where a.id =1 and b.id=1 |
    Then check resultset "rs_14" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                   |
      | dn2         | BASE SQL | select * from aly_test a join tb_test b on a.c=b.c where a.id =1 and b.id=1 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_15"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join schema2.tb_test b on a.c=b.c where a.id =1 and b.id=2 |
    Then check resultset "rs_15" has lines with following column values
      | DATA_NODE-0     | TYPE-1        | SQL/REF-2                                                                            |
      | dn2_0           | BASE SQL      | select `a`.`id`,`a`.`c` from  `aly_test` `a` where `a`.`id` = 1 ORDER BY `a`.`c` ASC |
      | merge_1         | MERGE         | dn2_0                                                                                |
      | shuffle_field_1 | SHUFFLE_FIELD | merge_1                                                                              |
      | dn3_0           | BASE SQL      | select `b`.`id`,`b`.`c` from  `tb_test` `b` where `b`.`id` = 2 ORDER BY `b`.`c` ASC  |
      | merge_2         | MERGE         | dn3_0                                                                                |
      | shuffle_field_3 | SHUFFLE_FIELD | merge_2                                                                              |
      | join_1          | JOIN          | shuffle_field_1; shuffle_field_3                                                     |
      | shuffle_field_2 | SHUFFLE_FIELD | join_1                                                                               |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_16"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join a_three b on a.c = b.c where (a.id =4 and b.id=1) or (a.id=4 and b.id=2) |
    Then check resultset "rs_16" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                                              |
      | dn1         | BASE SQL | select * from aly_test a join a_three b on a.c = b.c where (a.id =4 and b.id=1) or (a.id=4 and b.id=2) |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_17"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join aly_order b on a.c = b.c where (a.id =1 and b.id=1) or (a.id=2 and b.id=2) |
    Then check resultset "rs_17" has lines with following column values
      | DATA_NODE-0       | TYPE-1          | SQL/REF-2                                                                                                 |
      | dn2_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` where (`a`.`id` = 1) OR (`a`.`id` = 2) ORDER BY `a`.`c` ASC  |
      | dn3_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` where (`a`.`id` = 1) OR (`a`.`id` = 2) ORDER BY `a`.`c` ASC  |
      | merge_and_order_1 | MERGE_AND_ORDER | dn2_0; dn3_0                                                                                              |
      | shuffle_field_1   | SHUFFLE_FIELD   | merge_and_order_1                                                                                         |
      | dn2_1             | BASE SQL        | select `b`.`id`,`b`.`c` from  `aly_order` `b` where (`b`.`id` = 1) OR (`b`.`id` = 2) ORDER BY `b`.`c` ASC |
      | dn3_1             | BASE SQL        | select `b`.`id`,`b`.`c` from  `aly_order` `b` where (`b`.`id` = 1) OR (`b`.`id` = 2) ORDER BY `b`.`c` ASC |
      | merge_and_order_2 | MERGE_AND_ORDER | dn2_1; dn3_1                                                                                              |
      | shuffle_field_3   | SHUFFLE_FIELD   | merge_and_order_2                                                                                         |
      | join_1            | JOIN            | shuffle_field_1; shuffle_field_3                                                                          |
      | where_filter_1    | WHERE_FILTER    | join_1                                                                                                    |
      | shuffle_field_2   | SHUFFLE_FIELD   | where_filter_1                                                                                            |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_18"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join a_three b on a.c = b.c where (a.id =4 and b.id=1) or (a.id=3) |
    Then check resultset "rs_18" has lines with following column values
      | DATA_NODE-0       | TYPE-1          | SQL/REF-2                                                                                               |
      | dn1_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` where (`a`.`id` = 4) OR (a.id IN (3)) ORDER BY `a`.`c` ASC |
      | dn4_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` where (`a`.`id` = 4) OR (a.id IN (3)) ORDER BY `a`.`c` ASC |
      | merge_and_order_1 | MERGE_AND_ORDER | dn1_0; dn4_0                                                                                            |
      | shuffle_field_1   | SHUFFLE_FIELD   | merge_and_order_1                                                                                       |
      | dn1_1             | BASE SQL        | select `b`.`id`,`b`.`c` from  `a_three` `b` ORDER BY `b`.`c` ASC                                        |
      | dn2_0             | BASE SQL        | select `b`.`id`,`b`.`c` from  `a_three` `b` ORDER BY `b`.`c` ASC                                        |
      | dn3_0             | BASE SQL        | select `b`.`id`,`b`.`c` from  `a_three` `b` ORDER BY `b`.`c` ASC                                        |
      | merge_and_order_2 | MERGE_AND_ORDER | dn1_1; dn2_0; dn3_0                                                                                     |
      | shuffle_field_3   | SHUFFLE_FIELD   | merge_and_order_2                                                                                       |
      | join_1            | JOIN            | shuffle_field_1; shuffle_field_3                                                                        |
      | where_filter_1    | WHERE_FILTER    | join_1                                                                                                  |
      | shuffle_field_2   | SHUFFLE_FIELD   | where_filter_1                                                                                          |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_19"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join aly_order b on a.id = b.id where a.id =1 |
    Then check resultset "rs_19" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                              |
      | dn2         | BASE SQL | select * from aly_test a join aly_order b on a.id = b.id where a.id =1 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_20"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join aly_order b using(id,c)  where a.id=2 or b.id=1 |
    Then check resultset "rs_20" has lines with following column values
      | DATA_NODE-0     | TYPE-1        | SQL/REF-2                                                                                                                                            |
      | dn2_0           | BASE SQL      | select `a`.`id`,`a`.`c` from  `aly_test` `a` join  `aly_order` `b` on `a`.`id` = `b`.`id` and `a`.`c` = `b`.`c` where (b.id IN (1)) OR (a.id IN (2)) |
      | dn3_0           | BASE SQL      | select `a`.`id`,`a`.`c` from  `aly_test` `a` join  `aly_order` `b` on `a`.`id` = `b`.`id` and `a`.`c` = `b`.`c` where (b.id IN (1)) OR (a.id IN (2)) |
      | merge_1         | MERGE         | dn2_0; dn3_0                                                                                                                                         |
      | shuffle_field_1 | SHUFFLE_FIELD | merge_1                                                                                                                                              |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_21"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join a_manager b using(id,c)  where a.id=2 or b.id=1 |
    Then check resultset "rs_21" has lines with following column values
      | DATA_NODE-0       | TYPE-1          | SQL/REF-2                                                                       |
      | dn1_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` ORDER BY `a`.`id` ASC,`a`.`c` ASC  |
      | dn2_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` ORDER BY `a`.`id` ASC,`a`.`c` ASC  |
      | dn3_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` ORDER BY `a`.`id` ASC,`a`.`c` ASC  |
      | dn4_0             | BASE SQL        | select `a`.`id`,`a`.`c` from  `aly_test` `a` ORDER BY `a`.`id` ASC,`a`.`c` ASC  |
      | merge_and_order_1 | MERGE_AND_ORDER | dn1_0; dn2_0; dn3_0; dn4_0                                                      |
      | shuffle_field_1   | SHUFFLE_FIELD   | merge_and_order_1                                                               |
      | dn1_1             | BASE SQL        | select `b`.`id`,`b`.`c` from  `a_manager` `b` ORDER BY `b`.`id` ASC,`b`.`c` ASC |
      | dn2_1             | BASE SQL        | select `b`.`id`,`b`.`c` from  `a_manager` `b` ORDER BY `b`.`id` ASC,`b`.`c` ASC |
      | dn3_1             | BASE SQL        | select `b`.`id`,`b`.`c` from  `a_manager` `b` ORDER BY `b`.`id` ASC,`b`.`c` ASC |
      | dn4_1             | BASE SQL        | select `b`.`id`,`b`.`c` from  `a_manager` `b` ORDER BY `b`.`id` ASC,`b`.`c` ASC |
      | merge_and_order_2 | MERGE_AND_ORDER | dn1_1; dn2_1; dn3_1; dn4_1                                                      |
      | shuffle_field_3   | SHUFFLE_FIELD   | merge_and_order_2                                                               |
      | join_1            | JOIN            | shuffle_field_1; shuffle_field_3                                                |
      | where_filter_1    | WHERE_FILTER    | join_1                                                                          |
      | shuffle_field_2   | SHUFFLE_FIELD   | where_filter_1                                                                  |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_22"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join aly_order b where a.id = b.id and a.id =1 |
    Then check resultset "rs_22" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                               |
      | dn2         | BASE SQL | select * from aly_test a join aly_order b where a.id = b.id and a.id =1 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_23"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join aly_order b using(id)  where a.id =1 |
    Then check resultset "rs_23" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                          |
      | dn2         | BASE SQL | select * from aly_test a join aly_order b using(id)  where a.id =1 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_24"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from aly_test a join aly_order b on a.id = b.id where a.id =1 |
    Then check resultset "rs_24" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                              |
      | dn2         | BASE SQL | select * from aly_test a join aly_order b on a.id = b.id where a.id =1 |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_25"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 ))  |
    Then check resultset "rs_25" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                                                                                     |
      | dn1         | BASE SQL | select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 )) |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_26"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and a.c_decimal=1 and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 )) |
    Then check resultset "rs_26" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                                                                                                       |
      | dn1         | BASE SQL | select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and a.c_decimal=1 and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 )) |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_27"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and (a.c_decimal=1 and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 ))) |
    Then check resultset "rs_27" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                                                                                                         |
      | dn1         | BASE SQL | select * from sharding_two_node a join sharding_two_node2 b where a.id =b.id and (a.c_decimal=1 and (( a.id =1 and b.id=1) or ( a.c_flag=b.c_flag and a.id =2 ))) |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_28"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from sharding_two_node where id =1 and c_flag = (select c_flag from sharding_two_node2 where id =1 ) |
    Then check resultset "rs_28" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                                                     |
      | dn1         | BASE SQL | select * from sharding_two_node where id =1 and c_flag = (select c_flag from sharding_two_node2 where id =1 ) |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_29"
      | conn   | toClose | sql                                                                        |
      | conn_0 | False   | explain select * from sharding_two_node where id =1 and c_flag = (select c_flag from sharding_two_node2 where id =512 ) |
    Then check resultset "rs_29" has lines with following column values
      | DATA_NODE-0        | TYPE-1                | SQL/REF-2                                                                                                                                                                                                                                |
      | dn2_0              | BASE SQL              | select `sharding_two_node2`.`c_flag` as `autoalias_scalar` from  `sharding_two_node2` where `sharding_two_node2`.`id` = 512 LIMIT 2                                                                                                      |
      | merge_1            | MERGE                 | dn2_0                                                                                                                                                                                                                                    |
      | limit_1            | LIMIT                 | merge_1                                                                                                                                                                                                                                  |
      | shuffle_field_1    | SHUFFLE_FIELD         | limit_1                                                                                                                                                                                                                                  |
      | scalar_sub_query_1 | SCALAR_SUB_QUERY      | shuffle_field_1                                                                                                                                                                                                                          |
      | dn1_0              | BASE SQL(May No Need) | scalar_sub_query_1; select `sharding_two_node`.`id`,`sharding_two_node`.`c_flag`,`sharding_two_node`.`c_decimal` from  `sharding_two_node` where (`sharding_two_node`.`id` = 1) AND (`sharding_two_node`.`c_flag` = '{NEED_TO_REPLACE}') |
      | merge_2            | MERGE                 | dn1_0                                                                                                                                                                                                                                    |
      | shuffle_field_2    | SHUFFLE_FIELD         | merge_2                                                                                                                                                                                                                                  |

    Given execute single sql in "dble-1" in "user" mode and save resultset in "rs_30"
      | conn   | toClose | sql                                                                        |
      | conn_0 | True    | explain select * from sharding_two_node where id =1 union select * from sharding_two_node2 where id =1 |
    Then check resultset "rs_30" has lines with following column values
      | DATA_NODE-0 | TYPE-1   | SQL/REF-2                                                                                      |
      | dn1         | BASE SQL | select * from sharding_two_node where id =1 union select * from sharding_two_node2 where id =1 |
