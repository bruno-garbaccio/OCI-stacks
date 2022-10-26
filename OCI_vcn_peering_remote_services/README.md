# Stack to create a Remote Peering between 2 Oracle Cloud Infrastructure OCI Regions. 


./architecture_diagram.png


## Acknowledments

This stack takes https://github.com/cpauliat/my-terraform-oci-examples/tree/master/13_OCI_demo_vcn_peering_remote as a baseline.

Additionally, it follows the recommendations from https://medium.com/oracledevs/how-to-securely-connect-cross-regional-oci-services-via-the-service-gateway-61646b470a20


## Policies to deploy the stack: 
```
allow service compute_management to use tag-namespace in tenancy
allow service compute_management to manage compute-management-family in tenancy
allow service compute_management to read app-catalog-listing in tenancy
allow group user to manage all-resources in compartment compartmentName
```

## Expected behaviour

This stack creates a Remote Peering between 2 OCI Regions. After execution, Region 1 and Region 2 have one Virtual Cloud Network (VCN) each. Each VCN contains the following:

    2 Subnets (public and private)
    1 Internet Gateway
    1 Nat Gateway
    1 Service Gateway
    1 Dynamic Routing Gateway (DRG) attachement

Additionally, it is possible to use the OCI Services from Region 2 in Region 1 and vice versa even if the NAT traffic is blocked (only Service Gateway and DRG active). This includes also access to Object Storage in both regions.