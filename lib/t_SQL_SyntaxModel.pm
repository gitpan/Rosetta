# This module contains sample input and output data which is used to test 
# SQL::SyntaxModel, and possibly other modules that are derived from it.

package # hide this class name from PAUSE indexer
t_SQL_SyntaxModel;
use strict;
use warnings;

######################################################################

sub make_a_node {
	my ($node_type, $node_id, $model) = @_;
	my $node = $model->create_empty_node( $node_type );
	$node->set_node_id( $node_id );
	$node->put_in_container( $model );
	$node->add_reciprocal_links();
	return( $node );
}

sub make_a_child_node {
	my ($node_type, $node_id, $pp_node, $pp_attr) = @_;
	my $node = $pp_node->create_empty_node( $node_type );
	$node->set_node_id( $node_id );
	$node->put_in_container( $pp_node->get_container() );
	$node->add_reciprocal_links();
	$node->set_node_ref_attribute( $pp_attr, $pp_node );
	$node->set_parent_node_attribute_name( $pp_attr );
	return( $node );
}

sub create_and_populate_model {
	my (undef, $class) = @_;

	my $model = $class->new();

	##### FIRST SET BLUEPRINT-TYPE DETAILS #####

	# Create user-defined data type domain that our database record primary keys are:
	my $dom_entity_id = make_a_node( 'domain', 1, $model );
	$dom_entity_id->set_literal_attribute( 'name', 'entity_id' );
	$dom_entity_id->set_enumerated_attribute( 'base_type', 'NUM_INT' );
	$dom_entity_id->set_literal_attribute( 'num_scale', 9 );

	# Create user-defined data type domain that our person names are:
	my $dom_pers_name = make_a_node( 'domain', 2, $model );
	$dom_pers_name->set_literal_attribute( 'name', 'person_name' );
	$dom_pers_name->set_enumerated_attribute( 'base_type', 'STR_CHAR' );
	$dom_pers_name->set_literal_attribute( 'max_chars', 100 );

	# Describe the database catalog blueprint that we will store our data in:
	my $catalog_bp = make_a_node( 'catalog', 1, $model );

	# Define the unrealized database user that owns our primary schema:
	my $owner = make_a_child_node( 'owner', 1, $catalog_bp, 'catalog' );

	# Define the primary schema that holds our data:
	my $schema = make_a_child_node( 'schema', 1, $catalog_bp, 'catalog' );
	$schema->set_literal_attribute( 'name', 'gene' );
	$schema->set_node_ref_attribute( 'owner', $owner );

	# Define the table that holds our data:
	my $tb_person = make_a_child_node( 'table', 1, $schema, 'schema' );
	$tb_person->set_literal_attribute( 'name', 'person' );

	# Define the 'person id' column of that table:
	my $tbc_person_id = make_a_child_node( 'table_col', 1, $tb_person, 'table' );
	$tbc_person_id->set_literal_attribute( 'name', 'person_id' );
	$tbc_person_id->set_node_ref_attribute( 'domain', $dom_entity_id );
	$tbc_person_id->set_literal_attribute( 'mandatory', 1 );
	$tbc_person_id->set_literal_attribute( 'default_val', 1 );
	$tbc_person_id->set_literal_attribute( 'auto_inc', 1 );

	# Define the 'person name' column of that table:
	my $tbc_person_name = make_a_child_node( 'table_col', 2, $tb_person, 'table' );
	$tbc_person_name->set_literal_attribute( 'name', 'name' );
	$tbc_person_name->set_node_ref_attribute( 'domain', $dom_pers_name );
	$tbc_person_name->set_literal_attribute( 'mandatory', 1 );

	# Define the 'father' column of that table:
	my $tbc_father_id = make_a_child_node( 'table_col', 3, $tb_person, 'table' );
	$tbc_father_id->set_literal_attribute( 'name', 'father_id' );
	$tbc_father_id->set_node_ref_attribute( 'domain', $dom_entity_id );
	$tbc_father_id->set_literal_attribute( 'mandatory', 0 );

	# Define the 'mother column of that table:
	my $tbc_mother_id = make_a_child_node( 'table_col', 4, $tb_person, 'table' );
	$tbc_mother_id->set_literal_attribute( 'name', 'mother_id' );
	$tbc_mother_id->set_node_ref_attribute( 'domain', $dom_entity_id );
	$tbc_mother_id->set_literal_attribute( 'mandatory', 0 );

	# Define the table primary key constraint on person.person_id:
	my $ipk_person = make_a_child_node( 'table_ind', 1, $tb_person, 'table' );
	$ipk_person->set_literal_attribute( 'name', 'primary' );
	$ipk_person->set_enumerated_attribute( 'ind_type', 'UNIQUE' );
	my $icpk_person = make_a_child_node( 'table_ind_col', 1, $ipk_person, 'table_ind' );
	$icpk_person->set_node_ref_attribute( 'table_col', $tbc_person_id );

	# Define a table foreign key constraint on person.father_id to person.person_id:
	my $ifk_father = make_a_child_node( 'table_ind', 2, $tb_person, 'table' );
	$ifk_father->set_literal_attribute( 'name', 'fk_father' );
	$ifk_father->set_enumerated_attribute( 'ind_type', 'FOREIGN' );
	$ifk_father->set_node_ref_attribute( 'f_table', $tb_person );
	my $icfk_father = make_a_child_node( 'table_ind_col', 2, $ifk_father, 'table_ind' );
	$icfk_father->set_node_ref_attribute( 'table_col', $tbc_father_id );
	$icfk_father->set_node_ref_attribute( 'f_table_col', $tbc_person_id );

	# Define a table foreign key constraint on person.mother_id to person.person_id:
	my $ifk_mother = make_a_child_node( 'table_ind', 3, $tb_person, 'table' );
	$ifk_mother->set_literal_attribute( 'name', 'fk_mother' );
	$ifk_mother->set_enumerated_attribute( 'ind_type', 'FOREIGN' );
	$ifk_mother->set_node_ref_attribute( 'f_table', $tb_person );
	my $icfk_mother = make_a_child_node( 'table_ind_col', 3, $ifk_mother, 'table_ind' );
	$icfk_mother->set_node_ref_attribute( 'table_col', $tbc_mother_id );
	$icfk_mother->set_node_ref_attribute( 'f_table_col', $tbc_person_id );

	# Describe a utility application for managing our database schema:
	my $setup_app = make_a_node( 'application', 1, $model );
	$setup_app->set_literal_attribute( 'name', 'Setup' );

	# Describe the data link that the utility app will use to talk to the database:
	my $setup_app_dl = make_a_child_node( 'catalog_link', 1, $setup_app, 'application' );
	$setup_app_dl->set_literal_attribute( 'name', 'admin_link' );
	$setup_app_dl->set_node_ref_attribute( 'target', $catalog_bp );

	# MOCKUP: Describe a routine for setting up a database with our schema:
	my $rt_install = make_a_child_node( 'routine', 1, $setup_app, 'application' );
	$rt_install->set_enumerated_attribute( 'routine_type', 'ANONYMOUS' );
	$rt_install->set_literal_attribute( 'name', 'install_app_schema' );
	my $rt_install_a1 = make_a_child_node( 'routine_stmt', 1, $rt_install, 'routine' );
	$rt_install_a1->set_enumerated_attribute( 'stmt_type', 'COMMAND' ); # MOCKUP
	$rt_install_a1->set_enumerated_attribute( 'command', 'DB_CREATE' ); # MOCKUP
	$rt_install_a1->set_literal_attribute( 'command_arg', '1' ); # MOCKUP

	# MOCKUP: Describe a routine for tearing down a database with our schema:
	my $rt_remove = make_a_child_node( 'routine', 2, $setup_app, 'application' );
	$rt_remove->set_enumerated_attribute( 'routine_type', 'ANONYMOUS' );
	$rt_remove->set_literal_attribute( 'name', 'remove_app_schema' );
	my $rt_remove_a1 = make_a_child_node( 'routine_stmt', 2, $rt_remove, 'routine' );
	$rt_remove_a1->set_enumerated_attribute( 'stmt_type', 'COMMAND' ); # MOCKUP
	$rt_remove_a1->set_enumerated_attribute( 'command', 'DB_DELETE' ); # MOCKUP
	$rt_remove_a1->set_literal_attribute( 'command_arg', '1' ); # MOCKUP

	# Describe a 'normal' application for viewing and editing database records:
	my $editor_app = make_a_node( 'application', 2, $model );
	$editor_app->set_literal_attribute( 'name', 'People Watcher' );

	# Describe the data link that the normal app will use to talk to the database:
	my $editor_app_dl = make_a_child_node( 'catalog_link', 2, $editor_app, 'application' );
	$editor_app_dl->set_literal_attribute( 'name', 'editor_link' );
	$editor_app_dl->set_node_ref_attribute( 'target', $catalog_bp );

	# MOCKUP: Describe a routine that selects all records in the 'person' table:
	my $rt_fetchall = make_a_child_node( 'routine', 3, $editor_app, 'application' );
	$rt_fetchall->set_enumerated_attribute( 'routine_type', 'ANONYMOUS' );
	$rt_fetchall->set_literal_attribute( 'name', 'fetch_all_persons' );
	my $vw_fetchall = make_a_child_node( 'view', 1, $rt_fetchall, 'routine' );
	$vw_fetchall->set_enumerated_attribute( 'view_context', 'APPLIC' );
	$vw_fetchall->set_enumerated_attribute( 'view_type', 'MATCH' );
	$vw_fetchall->set_literal_attribute( 'match_all_cols', 1 );
	$vw_fetchall->set_literal_attribute( 'may_write', 1 );
	my $vw_fetchall_s1 = make_a_child_node( 'view_src', 1, $vw_fetchall, 'view' );
	$vw_fetchall_s1->set_literal_attribute( 'name', 'person' );
	$vw_fetchall_s1->set_node_ref_attribute( 'match_table', $tb_person );
	# ... then it opens and returns a cursor based on the view

	# MOCKUP: Describe a routine that inserts a record into the 'person' table:
	my $rt_insertone = make_a_child_node( 'routine', 4, $editor_app, 'application' );
	$rt_insertone->set_enumerated_attribute( 'routine_type', 'ANONYMOUS' );
	$rt_insertone->set_literal_attribute( 'name', 'insert_a_person' );
	# ... add the rest of this later

	# MOCKUP: Describe a routine that updates a record in the 'person' table:
	my $rt_updateone = make_a_child_node( 'routine', 5, $editor_app, 'application' );
	$rt_updateone->set_enumerated_attribute( 'routine_type', 'ANONYMOUS' );
	$rt_updateone->set_literal_attribute( 'name', 'update_a_person' );
	# ... add the rest of this later

	# MOCKUP: Describe a routine that deletes a record from the 'person' table:
	my $rt_deleteone = make_a_child_node( 'routine', 6, $editor_app, 'application' );
	$rt_deleteone->set_enumerated_attribute( 'routine_type', 'ANONYMOUS' );
	$rt_deleteone->set_literal_attribute( 'name', 'delete_a_person' );
	# ... add the rest of this later

	##### NEXT SET INSTANCE-TYPE DETAILS #####

	# Indicate one database product we will be using:
	my $dp_sqlite = make_a_node( 'database_product', 1, $model );
	$dp_sqlite->set_literal_attribute( 'product_code', 'SQLite_2_8_12' );
	$dp_sqlite->set_literal_attribute( 'is_file_based', 1 );

	# Indicate another database product we will be using:
	my $dp_oracle = make_a_node( 'database_product', 2, $model );
	$dp_oracle->set_literal_attribute( 'product_code', 'Oracle_9_i' );
	$dp_oracle->set_literal_attribute( 'is_network_svc', 1 );

	# Define the database catalog instance that our testers will log-in to:
	my $test_db = make_a_node( 'catalog_instance', 1, $model );
	$test_db->set_node_ref_attribute( 'blueprint', $catalog_bp );
	$test_db->set_literal_attribute( 'name', 'test' );
	$test_db->set_node_ref_attribute( 'product', $dp_sqlite );

	# Define the database catalog instance that marketers will demonstrate with:
	my $demo_db = make_a_node( 'catalog_instance', 2, $model );
	$demo_db->set_node_ref_attribute( 'blueprint', $catalog_bp );
	$demo_db->set_literal_attribute( 'name', 'demo' );
	$demo_db->set_node_ref_attribute( 'product', $dp_oracle );

	# Define the database user that owns the testing db schema:
	my $ownerI1 = make_a_child_node( 'user', 1, $test_db, 'catalog' );
	$ownerI1->set_enumerated_attribute( 'user_type', 'SCHEMA_OWNER' );
	$ownerI1->set_node_ref_attribute( 'match_owner', $owner );
	$ownerI1->set_literal_attribute( 'name', 'ronsealy' );
	$ownerI1->set_literal_attribute( 'password', 'K34dsD' );

	# Define a 'normal' database user that will work with the testing database:
	my $tester = make_a_child_node( 'user', 2, $test_db, 'catalog' );
	$tester->set_enumerated_attribute( 'user_type', 'DATA_EDITOR' );
	$tester->set_literal_attribute( 'name', 'joesmith' );
	$tester->set_literal_attribute( 'password', 'fdsKJ4' );

	# Define the database user that owns the demo db schema:
	my $ownerI2 = make_a_child_node( 'user', 3, $demo_db, 'catalog' );
	$ownerI2->set_enumerated_attribute( 'user_type', 'SCHEMA_OWNER' );
	$ownerI2->set_node_ref_attribute( 'match_owner', $owner );
	$ownerI2->set_literal_attribute( 'name', 'florence' );
	$ownerI2->set_literal_attribute( 'password', '0sfs8G' );

	# Define a 'normal' user that will work with the demo db:
	my $marketer = make_a_child_node( 'user', 4, $demo_db, 'catalog' );
	$marketer->set_enumerated_attribute( 'user_type', 'DATA_EDITOR' );
	$marketer->set_literal_attribute( 'name', 'thainuff' );
	$marketer->set_literal_attribute( 'password', '9340sd' );

	# ... we are still missing a bunch of things in this example ...

	# Now check that we didn't omit something important:
	$model->with_all_nodes_test_mandatory_attributes();

	return( $model );
}

######################################################################

sub expected_model_xml_output {
	return(
'<root>
	<elements>
		<domain id="1" name="entity_id" base_type="NUM_INT" num_scale="9" />
		<domain id="2" name="person_name" base_type="STR_CHAR" max_chars="100" />
	</elements>
	<blueprints>
		<catalog id="1">
			<owner id="1" catalog="1" />
			<schema id="1" catalog="1" name="gene" owner="1">
				<table id="1" schema="1" name="person">
					<table_col id="1" table="1" name="person_id" domain="1" mandatory="1" default_val="1" auto_inc="1" />
					<table_col id="2" table="1" name="name" domain="2" mandatory="1" />
					<table_col id="3" table="1" name="father_id" domain="1" mandatory="0" />
					<table_col id="4" table="1" name="mother_id" domain="1" mandatory="0" />
					<table_ind id="1" table="1" name="primary" ind_type="UNIQUE">
						<table_ind_col id="1" table_ind="1" table_col="1" />
					</table_ind>
					<table_ind id="2" table="1" name="fk_father" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="2" table_ind="2" table_col="3" f_table_col="1" />
					</table_ind>
					<table_ind id="3" table="1" name="fk_mother" ind_type="FOREIGN" f_table="1">
						<table_ind_col id="3" table_ind="3" table_col="4" f_table_col="1" />
					</table_ind>
				</table>
			</schema>
		</catalog>
		<application id="1" name="Setup">
			<catalog_link id="1" application="1" name="admin_link" target="1" />
			<routine id="1" routine_type="ANONYMOUS" application="1" name="install_app_schema">
				<routine_stmt id="1" routine="1" stmt_type="COMMAND" command="DB_CREATE" command_arg="1" />
			</routine>
			<routine id="2" routine_type="ANONYMOUS" application="1" name="remove_app_schema">
				<routine_stmt id="2" routine="2" stmt_type="COMMAND" command="DB_DELETE" command_arg="1" />
			</routine>
		</application>
		<application id="2" name="People Watcher">
			<catalog_link id="2" application="2" name="editor_link" target="1" />
			<routine id="3" routine_type="ANONYMOUS" application="2" name="fetch_all_persons">
				<view id="1" view_context="APPLIC" view_type="MATCH" routine="3" match_all_cols="1" may_write="1">
					<view_src id="1" view="1" name="person" match_table="1" />
				</view>
			</routine>
			<routine id="4" routine_type="ANONYMOUS" application="2" name="insert_a_person" />
			<routine id="5" routine_type="ANONYMOUS" application="2" name="update_a_person" />
			<routine id="6" routine_type="ANONYMOUS" application="2" name="delete_a_person" />
		</application>
	</blueprints>
	<tools>
		<database_product id="1" product_code="SQLite_2_8_12" is_file_based="1" />
		<database_product id="2" product_code="Oracle_9_i" is_network_svc="1" />
	</tools>
	<sites>
		<catalog_instance id="1" blueprint="1" name="test" product="1">
			<user id="1" catalog="1" user_type="SCHEMA_OWNER" match_owner="1" name="ronsealy" password="K34dsD" />
			<user id="2" catalog="1" user_type="DATA_EDITOR" name="joesmith" password="fdsKJ4" />
		</catalog_instance>
		<catalog_instance id="2" blueprint="1" name="demo" product="2">
			<user id="3" catalog="2" user_type="SCHEMA_OWNER" match_owner="1" name="florence" password="0sfs8G" />
			<user id="4" catalog="2" user_type="DATA_EDITOR" name="thainuff" password="9340sd" />
		</catalog_instance>
	</sites>
	<circumventions />
</root>
'
	);
}

######################################################################

1;
