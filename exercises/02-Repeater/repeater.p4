/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

struct metadata {
}

struct headers {
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

      state start{
          transition accept;
      }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    /* TODO 2: For solution 2 -> define an action that modifies the egress_port */
    action set_egress_port(bit<9> desired_egress_port) {
      standard_metadata.egress_spec = desired_egress_port;
    }

    /* TODO 1: For solution 2 -> define a table that matches standard_metadata.ingress_port */
    table port_match {
      key = {standard_metadata.ingress_port: exact;}

      actions = {
        set_egress_port;
        NoAction;
      }
      size = 2;
      default_action = NoAction;
    }

    apply {
        
        /* Solution 2: Apply the table you use */
        port_match.apply();

        /* Solution 1: Without tables, write the algorithm directly here*/
        /*if (standard_metadata.ingress_port == 1) {
          standard_metadata.egress_spec = 2;
        } else if (standard_metadata.ingress_port == 2) {
          standard_metadata.egress_spec = 1;
        }*/
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {

    /* Deparser not needed */

    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;