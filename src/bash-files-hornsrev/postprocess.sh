# CALCULATE AEPS WITH SEVERAL DIFFERENT WIND ROSE FIDELITY LEVELS AND WAKE MODELS

# set what analyses to run
calculate_aeps=true
plot_layouts=false
plot_aeps=false
plot_montecarlo=false

# set model parameters
nturbines_vec=(80)
ndirs_vec=(12 36 72 120 360)
ndirs_vec_julia=[12,36,72,120,360]
nspeeds_vec=(1 5 10 15 20 25)
nspeeds_vec_julia=[01,05,10,15,20,25]
windrose=HornsRevWindRose
turbine_type=VestasV80_2MW
wake_model_vec=(JensenCosine) #(GaussYawVariableSpread)
opt_algorithm=SnoptWECAlgorithm

# set layout numbers
layout_number_start=1
layout_number_end=20

# AEP plot parameters
aeps_fig_type=ConfidenceIntervalScatterPlot

# Monte Carlo plot parameters
sample_sizes=[]

# calculate and plot all AEP values for the specified layouts
for nturbines in ${nturbines_vec[@]}                                    # number of turbines
do
    for wake_model in ${wake_model_vec[@]}                          # optimization wake model
    do
        for analysis_wake_model in JensenCosine GaussYawVariableSpread #${wake_model_vec[@]}             # analysis wake model
        do
            aeps_file_name="final-aeps-${analysis_wake_model}.txt"

            for ndirs in ${ndirs_vec[@]}                            # number of wind directions used for optimization
            do
                ndirs=$(printf %3s $ndirs | tr ' ' 0)

                for nspeeds in ${nspeeds_vec[@]}                    # number of wind speeds used for optimization
                do
                    nspeeds=$(printf %2s $nspeeds | tr ' ' 0)

                    if $calculate_aeps == true
                    then
                        # calculate AEP values
                        layouts_directory_path="../results/final-layouts/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
                        aeps_directory_path="../results/final-aeps/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
                        aeps_file_path=$aeps_directory_path$aeps_file_name
                        julia calc_aeps.jl \
                            360 \
                            25 \
                            $windrose \
                            $nturbines \
                            $turbine_type \
                            $analysis_wake_model \
                            $layout_number_start \
                            $layout_number_end \
                            $layouts_directory_path \
                            $aeps_directory_path \
                            $aeps_file_name
                    fi
                done

                if $plot_layouts == true
                then
                    # plot all layouts overlayed on each other for a specific direction-speed fidelity combination
                    layout_plots_directory_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
                    layout_plots_file_name="final-layouts-plot.png"
                    julia plot_overlayed_layouts_by_direction_speed.jl $layout_number_start $layout_number_end $layouts_directory_path $layout_plots_directory_path $layout_plots_file_name
                fi
            done

            if $plot_aeps == true
            then
                # plot AEP values
                aeps_directory_partial_path="../results/final-aeps/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                aeps_plot_directory_path="../results/figures/aep-plots/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/reanalyzed-with-${analysis_wake_model}/"
                aeps_fig_title="AEP Values for Optimized, $nturbines-turbine, Horns Rev Wind Farm Layouts"
                julia plot_aeps.jl \
                    $ndirs_vec_julia \
                    $nspeeds_vec_julia \
                    $analysis_wake_model \
                    $layout_number_start \
                    $layout_number_end \
                    $aeps_directory_partial_path \
                    $aeps_file_name \
                    $aeps_plot_directory_path \
                    "$aeps_fig_title" \
                    $aeps_fig_type
            fi

            if $plot_montecarlo == true
            then
                # plot Monte Carlo results
                aeps_directory_partial_path="../results/final-aeps/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/"
                montecarlo_plot_directory_path="../results/figures/aep-plots/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/reanalyzed-with-${analysis_wake_model}/"
                aeps_fig_title=""
                julia plot_montecarlo.jl \
                    $ndirs_vec_julia \
                    $nspeeds_vec_julia \
                    $analysis_wake_model \
                    $layout_number_start \
                    $layout_number_end \
                    $aeps_directory_partial_path \
                    $aeps_file_name \
                    $montecarlo_plot_directory_path
            fi 
        done
    done
done

