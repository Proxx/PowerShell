Function Unlock-Screen { 
    [Cmdletbinding()]
    Param(
    [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )

    $InputObject.Close()
}
