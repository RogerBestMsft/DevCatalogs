$devCenterInput = @{
  name = 'VanArsdelLTDL'
  location = 'eastus'
  subscriptionId = '572b41e6-5c44-486a-84d2-01d6202774ac'
  resourceGroupName = 'VanArsdelLTD-RGL'
  keyVaultName = 'VanArsdelLTD-KVLLB'
  galleryName = 'vanarsdelltdgalleryLLB'
  repoUri = 'https://github.com/RBDDcet/DevCatalogs.git'
  repoAccess = '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'
  repoPath = '/DevCenter/Catalogs'
  vnet = @{
    name = 'VAGlobalNet'
    ipRanges = @(
      '20.0.0.0/16'
      )
    subnets = @(
      @{
        name = 'default'
        ipRange = '20.0.0.0/24'}
      @{
        name = 'subconnect'
        ipRange = '20.0.1.0/24'}
    )
  }
  environmentTypes = @(
    'Dev', 'Test', 'Production'
  )
  devboxDefinitions = @(
      @{
        name = 'AlphaDefinition'
        galleryName = 'default'
        imageName = 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
        imageVersion = 'latest'
        storage = '512'
        compute = '16c64gb'
      }
      @{
        name = 'BravoDefinition'
        galleryName = 'default'
        imageName = 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
        imageVersion = 'latest'
        storage = '512'
        compute = '16c64gb'
      }
    )
}

$projects = @(
  @{
    name = 'VanArsdelLTD-Alpha-Dev'
    subscriptionId = '572b41e6-5c44-486a-84d2-01d6202774ac'
    location = 'westus'
    resourceGroupName = 'VanArsdelLTD-Alpha-Dev-RG'
    projectAdmins = @('c8307c6a-8539-4540-8e45-e8fa520fd93c')
    devboxUsers = @('c8307c6a-8539-4540-8e45-e8fa520fd93c','36d7224b-8dc1-4a01-89c3-358d8f0ac3eb')
    adeUsers = @('36d7224b-8dc1-4a01-89c3-358d8f0ac3eb')
    vnet = @(
      @{
        name = 'VanArsdelLTD-Alpha-Dev-Vnet'
        domainjoinType = 'AzureADJoin'
        ipranges = @(
          '21.0.0.0/16'
        )
        subnets = @(
          @{
            name = 'default'
            iprange = '21.0.0.0/24'}
          @{
            name = 'subconnect'
            iprange = '21.0.1.0/24'}
        )
      }
      @{
        name = 'VanArsdelLTD-Alpha-ADE-Vnet'
        domainjoinType = 'None'
        ipranges = @(
          '32.0.0.0/16'
        )
        subnets = @(
          @{
            name = 'default'
            iprange = '32.0.0.0/24'}
          @{
            name = 'subconnect'
            iprange = '32.0.1.0/24'
          }
        )
      }
    )
    environmentTypes = @(
      @{
        type = 'Production'
        subscriptionId = '572b41e6-5c44-486a-84d2-01d6202774ac'
        identity = @{
          type = 'SystemAssigned'
        }
        creatorRoles = @(
          '18e40d4e-8d2e-438d-97e1-9528336e149c'
        )
      }
    )    
  }
  @{
    name = 'VanArsdelLTD-Bravo-Dev'
    subscriptionId = '572b41e6-5c44-486a-84d2-01d6202774ac'
    location = 'eastus'
    resourceGroupName = 'VanArsdelLTD-Bravo-Dev-RG'
    projectAdmins = @('36d7224b-8dc1-4a01-89c3-358d8f0ac3eb')
    devboxUsers = @('c8307c6a-8539-4540-8e45-e8fa520fd93c','36d7224b-8dc1-4a01-89c3-358d8f0ac3eb')
    adeUsers = @('36d7224b-8dc1-4a01-89c3-358d8f0ac3eb')
    vnet = @(
      @{
        name = 'VanArsdelLTD-Bravo-Dev-Vnet'
        domainjoinType = 'AzureADJoin'
        ipranges = @(
          '22.0.0.0/16'
        )
        subnets = @(
          @{
            name = 'default'
            iprange = '22.0.0.0/24'}
          @{
            name = 'subconnect'
            iprange = '22.0.1.0/24'}
        )
      }
      @{
        name = 'VanArsdelLTD-Bravo-ADE-Vnet'
        domainjoinType = 'None'
        ipranges = @(
          '32.0.0.0/16'
        )
        subnets = @(
          @{
            name = 'default'
            iprange = '32.0.0.0/24'}
          @{
            name = 'subconnect'
            iprange = '32.0.1.0/24'
          }
        )
      }
    )
    environmentTypes = @(
      @{
        name = 'Dev'
        location = 'eastus'
        subscriptionId = '572b41e6-5c44-486a-84d2-01d6202774ac'
        identity = @{
          idtype = 'SystemAssigned'
        }
        creatorRoles = @(
          'b24988ac-6180-42a0-ab88-20f7382dd24c'
        )
      }
      @{
        name = 'Test'
        location = 'eastus'
        subscriptionId = '572b41e6-5c44-486a-84d2-01d6202774ac'
        identity = @{
          idtype = 'SystemAssigned'
        }
        creatorRoles = @(
          'b24988ac-6180-42a0-ab88-20f7382dd24c'
        )
      }
    )    
    pools = @(

    )
  }
)

