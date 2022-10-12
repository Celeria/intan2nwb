function metrics_out = computeQualityMetrics()

for ii = 1 : n_units
    
    % Grab from kilosort
    metrics_out.quality(ii)             = ;

    % Ones needed to be computed
    metrics_out.firing_rate(ii)         = firingRate(spike_train, , );
    metrics_out.isi_violations(ii)      = isiViolations(spike_train, , );
    metrics_out.presence_ration(ii)     = presenceRatio(spike_train);

end

end