/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> L2_LEARN_ETHER_TYPE = 0x1234;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<16> port16_t;
typedef bit<9>  port9_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

//TODO 2: define a new header type and name it `cpu_t`
header cpu_t {
    macAddr_t   srcAddr;
    port16_t      ingress_port;
}

struct metadata {
    //TODO 3: define a metadata field to carry the ingress_port with the cloned packet
    port9_t ingress_port;
}

struct headers {
    ethernet_t   ethernet;
    //TODO 4: add cpu header to headers
    cpu_t      cpu;
}


/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        packet.extract(hdr.ethernet);
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

    action drop() {

        mark_to_drop(standard_metadata);
    }

    //TODO 7: Define the smac table and the mac_learn action
    action mac_learn() {
        meta.ingress_port = standard_metadata.ingress_port;
        //signature: clone3(in CloneType type, in bit<32> session, in T data)
        bit<32> mirroring_id = 100;
        clone3(CloneType.I2E, mirroring_id, meta);
    }

    table smac {
        key = {
            hdr.ethernet.srcAddr: exact;
        }
        actions = {
            mac_learn;
            NoAction;
        }
        size = 256;
        default_action = mac_learn;
    }


    //TODO 5: Define the dmac table and forward action
    action forward(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }
    table dmac {
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        actions = {
            forward;
            NoAction;
        }
        size = 256;
        default_action = NoAction;
    }

    //TODO 6: Define the broadcast table and the set_mcast_grp action
    action set_mcast_grp(bit<16> mcast_grp) {
        standard_metadata.mcast_grp = mcast_grp;
    }

    table broadcast {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            set_mcast_grp;
            NoAction;
        }
        size = 256;
        default_action = NoAction;
    }

    apply {
        smac.apply();
        // TODO 8: ingress logic, call the 3 tables
        if (! dmac.apply().hit) {
            broadcast.apply();
        }

    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    apply {

        //TODO 9: implement the egress logic: check if its a cloned packet, add cpu
        // header and fill its fields. Finally set the ethernet type to L2_LEARN_ETHER_TYPE (defined above).
        
        // Check if the instance_type is equal to 1 (which means that the packet is an ingress clone)
        if (standard_metadata.instance_type == 1) {
            // Activate the cpu header
            hdr.cpu.setValid();
            // Fill the cpu header with the mac source port and ingress port
            hdr.cpu.srcAddr = hdr.ethernet.srcAddr;
            hdr.cpu.ingress_port = (port16_t) meta.ingress_port;
            // Set the hdr.ethernet.etherType to 0x1234
            hdr.ethernet.etherType= L2_LEARN_ETHER_TYPE;

            // truncate packet after ether+cpu?
            truncate((bit<32>)22);
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {

    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        //parsed headers have to be added again into the packet.
        packet.emit(hdr.ethernet);
        //TODO 10: emit the cpu header
        packet.emit(hdr.cpu);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;